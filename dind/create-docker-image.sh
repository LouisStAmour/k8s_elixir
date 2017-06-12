#!/bin/sh

cd /gitsource/src3
cp ./Dockerfile.build ./Dockerfile

docker login "${DOCKER_REGISTRY}" --username "${DOCKER_USERNAME}" --password "${DOCKER_PASSWORD}"
docker build . -t "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4"
docker push       "${DOCKER_REGISTRY}/chgeuer/elixir:1.4.4"
