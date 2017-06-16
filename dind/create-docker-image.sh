#!/bin/sh

# src: https://raw.githubusercontent.com/chgeuer/k8s_elixir/master/dind/create-docker-image.sh

# curl -sSLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod 0755 /usr/local/bin/jq

echo "Running create-docker-image.sh"

# /usr/local/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=vfs 2>&1 > ~/docker.log &
/usr/local/bin/dockerd \
    --host=unix:///var/run/docker.sock \
    --host=tcp://0.0.0.0:2375 \
    --storage-driver=vfs \
    &

echo "Install JQ"
apk add --no-cache jq curl

DOCKER_REGISTRY=$(echo $DOCKER_SECRET_CFG | jq -r '. | keys[0]' | sed --expression="s_https://__")
DOCKER_USERNAME=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].username')
DOCKER_PASSWORD=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].password')

echo "DOCKER_REGISTRY ${DOCKER_REGISTRY}"
echo "DOCKER_USERNAME ${DOCKER_USERNAME}"
echo "DOCKER_PASSWORD ${DOCKER_PASSWORD}"

docker login "${DOCKER_REGISTRY}" \
       --username "${DOCKER_USERNAME}" \
       --password "${DOCKER_PASSWORD}"

function docker_tag_exists {
    EXISTS=$(curl --silent \
	    --basic \
	    --user "${DOCKER_USERNAME}:${DOCKER_PASSWORD}" \
	    -H "Content-Type: application/json" \
        --url "${DOCKER_REGISTRY}.azurecr.io/v2/$1/tags/list" \
        | jq ".tags" \
        | jq "contains([\"$2\"])")

    test $EXISTS = "true"
}

cd /git

##########################################

# $(docker pull "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4" 2>&1)

image="chgeuer/elixir"
tag="1.4.4"

if docker_tag_exists "${image}" "${tag}"; then
	echo "Image ${image}:${tag} already exists in ${DOCKER_REGISTRY}"
else 
    cd ./elixir
    docker build --tag "${DOCKER_REGISTRY}/${image}:${tag}" --file Dockerfile
    docker push        "${DOCKER_REGISTRY}/${image}:${tag}"
    cd ..
fi

##########################################

cd ./src3
docker build --tag "${DOCKER_REGISTRY}/chgeuer/appbuild:1.0.0" --file Dockerfile.build .

container_id=$(docker run --detach --entrypoint "/bin/sleep" "${DOCKER_REGISTRY}/chgeuer/appbuild:1.0.0" 1d)
docker exec "${container_id}" tar cvfz /k8s_elixir.tgz /opt/app/_build/prod/rel/k8s_elixir
docker cp "${container_id}:/k8s_elixir.tgz" ./k8s_elixir.tgz
docker stop "${container_id}"
docker rm "${container_id}"

docker build --tag "${DOCKER_REGISTRY}/chgeuer/app:1.0.0" --file Dockerfile.release .
docker push        "${DOCKER_REGISTRY}/chgeuer/app:1.0.0"
cd ..

##########################################

echo "Created all images"

kill -9 $(cat /var/run/docker.pid)

echo "Killed docker"
