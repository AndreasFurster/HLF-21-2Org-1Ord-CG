#!/bin/bash

COMPOSE_FILES="-f ./docker/docker-compose-org1.yaml -f ./docker/docker-compose-orderer.yaml"
IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} down --volumes --remove-orphans

rm -rf ./crypto-material/peerOrganizations
rm -rf ./crypto-material/ordererOrganizations
rm -rf ./system-genesis-block/*
rm -rf ./channel-artifacts/*
