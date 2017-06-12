#!/bin/sh

echo "Running create-docker-image.sh"

DOCKER_REGISTRY=$(echo $DOCKER_SECRET_CFG | jq -r '. | keys[0]')
DOCKER_USERNAME=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].username')
DOCKER_PASSWORD=$(echo $DOCKER_SECRET_CFG | jq -r '.[. | keys[0]].password')

echo "DOCKER_REGISTRY ${DOCKER_REGISTRY}"
echo "DOCKER_USERNAME ${DOCKER_USERNAME}"
echo "DOCKER_PASSWORD ${DOCKER_PASSWORD}"

cd /gitsource/src3
cp ./Dockerfile.build ./Dockerfile

docker login "${DOCKER_REGISTRY}" --username "${DOCKER_USERNAME}" --password "${DOCKER_PASSWORD}"
docker build . -t "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4"
docker push       "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4"
