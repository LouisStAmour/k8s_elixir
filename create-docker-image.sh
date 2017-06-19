#!/bin/sh

# src: https://raw.githubusercontent.com/chgeuer/k8s_elixir/master/create-docker-image.sh
# curl -sSLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod 0755 /usr/local/bin/jq

echo "Running create-docker-image.sh"

cd /git

# /usr/local/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=vfs 2>&1 > ~/docker.log &
/usr/local/bin/dockerd \
    --host=unix:///var/run/docker.sock \
    --host=tcp://0.0.0.0:2375 \
    --storage-driver=vfs \
    &

docker version

apk add --no-cache jq curl

DOCKER_REGISTRY=$(echo $DOCKER_SECRET_CFG | jq -r '. | keys[0]' | sed --expression="s_https://__")
DOCKER_USERNAME=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[]].username')
DOCKER_PASSWORD=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].password')

echo "DOCKER_REGISTRY ${DOCKER_REGISTRY}"
echo "DOCKER_USERNAME ${DOCKER_USERNAME}"
echo "DOCKER_PASSWORD ${DOCKER_PASSWORD}"

docker login "${DOCKER_REGISTRY}" \
       --username "${DOCKER_USERNAME}" \
       --password "${DOCKER_PASSWORD}"

##########################################

image="chgeuer/elixir"
tag="1.4.4"

image_exists=$(curl --silent \
	    --basic \
	    --user "${DOCKER_USERNAME}:${DOCKER_PASSWORD}" \
	    -H "Content-Type: application/json" \
        --url "https://${DOCKER_REGISTRY}/v2/$image/tags/list" \
        | jq ".tags" \
        | jq "contains([\"$tag\"])")

YELLOW='\033[1;33m'
NOCOLOR='\033[0m'

if [ "${image_exists}" = "true" ]; then
	echo -e "${YELLOW}Image ${image}:${tag} already exists in ${DOCKER_REGISTRY}${NOCOLOR}"
else 
    echo -e "${YELLOW}Image ${image}:${tag} seems to be missing in ${DOCKER_REGISTRY}${NOCOLORNC}"
    
    docker build \
           --tag "${DOCKER_REGISTRY}/${image}:${tag}" \
           --file Dockerfile.elixir  \
           .

    docker push "${DOCKER_REGISTRY}/${image}:${tag}"
fi

##########################################

cd src

appversion="1.0.1"

docker build \
       --tag "${DOCKER_REGISTRY}/chgeuer/appbuild:${appversion}" \
       --file Dockerfile.build \
       .

container_id=$(docker run --detach --entrypoint "/bin/sleep" "${DOCKER_REGISTRY}/chgeuer/appbuild:${appversion}" 1d)
docker exec "${container_id}" tar cvfz /k8s_elixir.tgz /opt/app/_build/prod/rel/k8s_elixir
docker cp   "${container_id}:/k8s_elixir.tgz" /git/src/k8s_elixir.tgz
# docker stop "${container_id}"
# docker rm   "${container_id}"

ls -als /git/src/k8s_elixir.tgz

docker build  \
       --tag "${DOCKER_REGISTRY}/chgeuer/app:${appversion}"  \
       --file /git/src/Dockerfile.release  \
       .

docker push "${DOCKER_REGISTRY}/chgeuer/app:${appversion}"

##########################################

echo "Created all images"

kill -9 $(cat /var/run/docker.pid)

echo "Killed docker"
