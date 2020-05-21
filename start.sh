#!/bin/bash

export FABRIC_CFG_PATH=${PWD}/config
CHANNEL_NAME="apchannel"
. ./utils/utils.sh
printSeparator "Generate crypto-material for Org1"
cryptogen generate --config=./cryptogen/crypto-config-org1.yaml --output="crypto-material"
printSeparator "Generate crypto-material for Org2"
cryptogen generate --config=./cryptogen/crypto-config-org2.yaml --output="crypto-material"
printSeparator "Generate crypto-material for Orderer"
cryptogen generate --config=./cryptogen/crypto-config-orderer.yaml --output="crypto-material"
printSeparator "Create Genesis-Block"
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
printSeparator "Start Network within Docker Containers"
docker-compose -f ./docker/docker-compose-org1.yaml -f ./docker/docker-compose-org2.yaml -f ./docker/docker-compose-orderer.yaml up -d
printSeparator "Create Channel Transaction"
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME && sleep 3
printSeparator "Create Anchor Peers Update for Org 1"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1
printSeparator "Create Anchor Peers Update for Org 2"
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2
printSeparator "Wait 3 seconds for network to come up" && sleep 3
printSeparator "Set Identity to Org1"
switchIdentity "Org1" 7051 && echoCurrentFabricEnvironment
printSeparator "Create channel"
peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer1.ap.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
printSeparator "Join Org1 to channel"
peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block && sleep 1
printSeparator "Set Identity to Org2"
switchIdentity "Org2" 8051 && echoCurrentFabricEnvironment && sleep 1
printSeparator "Join Org2 to channel"
peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
printSeparator "Update Anchor Peers as Org2"
peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer1.ap.com -c $CHANNEL_NAME -f ./channel-artifacts/ORG2MSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
printSeparator "Set Identity to Org1"
switchIdentity "Org1" 7051 && echoCurrentFabricEnvironment && sleep 1
printSeparator "Update Anchor Peers as Org1"
peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer1.ap.com -c $CHANNEL_NAME -f ./channel-artifacts/ORG1MSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
printSeparator "Done!"