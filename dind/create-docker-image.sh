#!/bin/sh

cd /gitsource/src3
cp ./Dockerfile.build ./Dockerfile
docker build .
docker login "chgeuerregistry1.azurecr.io" --username "${DOCKER_USERNAME}" --password "${DOCKER_PASSWORD}"
