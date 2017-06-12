#!/bin/sh

# cat /etc/*release

# curl -sSLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod 0755 /usr/local/bin/jq

echo "Running create-docker-image.sh"

echo "Install JQ"
apk add --no-cache jq

DOCKER_REGISTRY=$(echo $DOCKER_SECRET_CFG | jq -r '. | keys[0]' | sed --expression="s_https://__")
DOCKER_USERNAME=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].username')
DOCKER_PASSWORD=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].password')

echo "DOCKER_REGISTRY ${DOCKER_REGISTRY}"
echo "DOCKER_USERNAME ${DOCKER_USERNAME}"
echo "DOCKER_PASSWORD ${DOCKER_PASSWORD}"

docker login "${DOCKER_REGISTRY}" --username "${DOCKER_USERNAME}" --password "${DOCKER_PASSWORD}"

cd /gitsource


##########################################

# $(docker pull "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4" 2>&1)

cd ./elixir
docker build . -t "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4"
docker push       "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4"
cd ..


##########################################

cd ./src3
cp ./Dockerfile.build ./Dockerfile
docker build . -t "${DOCKER_REGISTRY}/chgeuer/app:1.0.0"
docker push       "${DOCKER_REGISTRY}/chgeuer/app:1.0.0"
cd ..


##########################################

echo "Created all images"
