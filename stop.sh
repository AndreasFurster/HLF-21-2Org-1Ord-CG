#!/bin/bash

. ./utils.sh

COMPOSE_FILES="-f ./docker/docker-compose-org1.yaml -f ./docker/docker-compose-org2.yaml -f ./docker/docker-compose-orderer.yaml"
IMAGE_TAG=$IMAGETAG 

printSeparator "Shutdown Docker containers, remove volumes and orphans"
docker-compose ${COMPOSE_FILES} down --volumes --remove-orphans

printSeparator "Delete generated files"
rm -r ./generated/*