#!/bin/bash

export FABRIC_CFG_PATH=${PWD}/config

. ./utils.sh

printSeparator "Generate crypto-material for Org1"
cryptogen generate --config=./cryptogen-input/crypto-config-org1.yaml --output="crypto-material"

printSeparator "Generate crypto-material for Org2"
cryptogen generate --config=./cryptogen-input/crypto-config-org2.yaml --output="crypto-material"

printSeparator "Generate crypto-material for Orderer"
cryptogen generate --config=./cryptogen-input/crypto-config-orderer.yaml --output="crypto-material"

printSeparator "Create Genesis-Block"
configtxgen -profile ApNetworkProfile -configPath ${PWD}/config -channelID system-channel -outputBlock ./system-genesis-block/genesis.block

printSeparator "Start Network within Docker Containers"
docker-compose -f ./docker/docker-compose-orderer.yaml -f ./docker/docker-compose-org1.yaml -f ./docker/docker-compose-org2.yaml up -d

printSeparator "Create Channel Transaction"
configtxgen -profile ApChannelProfile -configPath ${PWD}/config -outputCreateChannelTx ./channel-artifacts/apchannel.tx -channelID apchannel && sleep 3

printSeparator "Create Anchor Peers Update for Org 1"
configtxgen -profile ApChannelProfile -configPath ${PWD}/config -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID apchannel -asOrg Org1

printSeparator "Create Anchor Peers Update for Org 2"
configtxgen -profile ApChannelProfile -configPath ${PWD}/config -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID apchannel -asOrg Org2

printSeparator "Wait 3 seconds for network to come up" && sleep 3

printSeparator "Set Identity to Org1"
switchIdentity "Org1" 7051 && echoCurrentFabricEnvironment

printSeparator "Create channel"
peer channel create -o localhost:7050 -c apchannel --ordererTLSHostnameOverride orderer0.ap.com -f ./channel-artifacts/apchannel.tx --outputBlock ./channel-artifacts/apchannel.block --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA

printSeparator "Join Org1 to channel"
peer channel join -b ./channel-artifacts/apchannel.block && sleep 1

printSeparator "Update Anchor Peers as Org1"
peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer0.ap.com -c apchannel -f ./channel-artifacts/Org1MSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA

printSeparator "Set Identity to Org2"
switchIdentity "Org2" 8051 && echoCurrentFabricEnvironment && sleep 1

printSeparator "Join Org2 to channel"
peer channel join -b ./channel-artifacts/apchannel.block

printSeparator "Update Anchor Peers as Org2"
peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer0.ap.com -c apchannel -f ./channel-artifacts/Org2MSPanchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA

printSeparator "Set Identity to Org1"
switchIdentity "Org1" 7051 && echoCurrentFabricEnvironment

printSeparator "Install node modules for chaincode"
cd ./chaincode/
npm install
cd ../

printSeparator "Package chaincode"
peer lifecycle chaincode package mycc.tar.gz --path ./chaincode/ --lang node --label mycc_1

printSeparator "Install chaincode on Org1"
peer lifecycle chaincode install mycc.tar.gz
peer lifecycle chaincode queryinstalled

printSeparator "Approve chaincode on Org1"
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer0.ap.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID apchannel --name mycc_1 --version "1.0" --sequence "1"


switchIdentity "Org2" 8051 && echoCurrentFabricEnvironment && sleep 1

printSeparator "Install chaincode on Org2"
peer lifecycle chaincode install mycc.tar.gz
peer lifecycle chaincode queryinstalled

printSeparator "Approve chaincode on Org2"
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer0.ap.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID apchannel --name mycc_1 --version "1.0" --sequence "1"


switchIdentity "Org1" 7051 && echoCurrentFabricEnvironment

printSeparator "Check commit readiness (both orgs should be true)"
peer lifecycle chaincode checkcommitreadiness --channelID apchannel --name mycc_1 --version "1.0" --sequence "1"

printSeparator "Commit chaincode"
peer lifecycle chaincode commit -C apchannel -n mycc_1 -o localhost:7050 --ordererTLSHostnameOverride orderer0.ap.com --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --version "1.0"  --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE --peerAddresses localhost:7051 --sequence "1"

printSeparator "Query comitted chaincodes"
peer lifecycle chaincode querycommitted -C apchannel