#!/bin/bash

. ./utils.sh

COMPOSE_FILES="-f ./docker/docker-compose-org1.yaml -f ./docker/docker-compose-org2.yaml -f ./docker/docker-compose-orderer.yaml"
IMAGE_TAG=$IMAGETAG 

printSeparator "Shutdown Docker containers, remove volumes and orphans"
docker-compose ${COMPOSE_FILES} down --volumes --remove-orphans

printSeparator "Remove crypto-material"
rm -rf ./crypto-material/*

printSeparator "Remove genisis block"
rm -rf ./system-genesis-block/*

printSeparator "Remove channel artifacts"
rm -rf ./channel-artifacts/*

printSeparator "Remove chaincode packages"
rm -rf ./chaincode-packages/*
