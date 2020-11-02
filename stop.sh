#!/bin/bash

. ./utils.sh

COMPOSE_FILES="-f ./docker/docker-compose-coolblue.yaml -f ./docker/docker-compose-tweakers.yaml -f ./docker/docker-compose-daisycon.yaml"
IMAGE_TAG=$IMAGETAG 

printSeparator "Shutdown Docker containers, remove volumes and orphans"
docker-compose ${COMPOSE_FILES} down --volumes --remove-orphans

printSeparator "Delete generated files"
rm -rf ./generated/*