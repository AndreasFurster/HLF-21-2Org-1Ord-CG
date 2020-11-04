#!/bin/bash

export FABRIC_CFG_PATH=${PWD}/config

. ./utils.sh

printSeparator "Generate crypto-material for Coolblue"
cryptogen generate --config=./config/crypto-config-coolblue.yaml --output=./generated/crypto-material

printSeparator "Generate crypto-material for Tweakers"
cryptogen generate --config=./config/crypto-config-tweakers.yaml --output=./generated/crypto-material

printSeparator "Generate crypto-material for Orderer"
cryptogen generate --config=./config/crypto-config-daisycon.yaml --output=./generated/crypto-material

printSeparator "Create Genesis-Block"
configtxgen \
  -profile ApNetworkProfile \
  -configPath ${PWD}/config \
  -channelID system-channel \
  -outputBlock ./generated/system-genesis-block/genesis.block

printSeparator "Start Network within Docker Containers"
docker-compose \
  --file ./docker/docker-compose-daisycon.yaml \
  --file ./docker/docker-compose-coolblue.yaml \
  --file ./docker/docker-compose-tweakers.yaml up -d

printSeparator "Create Channel Transaction"
configtxgen \
  -profile ApChannelProfile \
  -configPath ${PWD}/config \
  -outputCreateChannelTx ./generated/channel-artifacts/apchannel.tx \
  -channelID apchannel && sleep 3

printSeparator "Create Anchor Peers Update for Org 1"
configtxgen \
  -profile ApChannelProfile \
  -configPath ${PWD}/config \
  -outputAnchorPeersUpdate ./generated/channel-artifacts/CoolblueMSPanchors.tx \
  -channelID apchannel \
  -asOrg Coolblue

printSeparator "Create Anchor Peers Update for Org 2"
configtxgen \
  -profile ApChannelProfile \
  -configPath ${PWD}/config \
  -outputAnchorPeersUpdate ./generated/channel-artifacts/TweakersMSPanchors.tx \
  -channelID apchannel \
  -asOrg Tweakers

printSeparator "Wait 3 seconds for network to come up"
sleep 3

printSeparator "Set Identity to Coolblue"
switchIdentity "Coolblue" 7051

printSeparator "Create channel"
peer channel create \
  --channelID apchannel \
  --file ./generated/channel-artifacts/apchannel.tx \
  --outputBlock ./generated/channel-artifacts/apchannel.block \
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer0.daisycon.sbc.andreasfurster.nl \
  --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA

printSeparator "Join Coolblue to channel"
peer channel join \
  --blockpath ./generated/channel-artifacts/apchannel.block 

sleep 1

printSeparator "Update Anchor Peers as Coolblue"
peer channel update \
  --channelID apchannel \
  --file ./generated/channel-artifacts/CoolblueMSPanchors.tx \
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer0.daisycon.sbc.andreasfurster.nl \
  --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA

printSeparator "Set Identity to Tweakers"
switchIdentity "Tweakers" 8051

printSeparator "Join Tweakers to channel"
peer channel join \
  --blockpath ./generated/channel-artifacts/apchannel.block

printSeparator "Update Anchor Peers as Tweakers"
peer channel update \
  --channelID apchannel \
  --file ./generated/channel-artifacts/TweakersMSPanchors.tx \
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer0.daisycon.sbc.andreasfurster.nl \
  --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA

printSeparator "Set Identity to Coolblue"
switchIdentity "Coolblue" 7051

printSeparator "Install node modules for chaincode"
cd ./chaincode/
npm install
cd ../

printSeparator "Package chaincode"
mkdir ./generated/chaincode-packages
peer lifecycle chaincode package ./generated/chaincode-packages/mycc.tar.gz \
  --path ./chaincode/ \
  --lang node \
  --label mycc_1

printSeparator "Install chaincode on Coolblue"
peer lifecycle chaincode install ./generated/chaincode-packages/mycc.tar.gz
peer lifecycle chaincode queryinstalled

printSeparator "Approve chaincode on Coolblue"
peer lifecycle chaincode approveformyorg \
  --channelID apchannel \
  --name mycc_1 \
  --version "1.0" \
  --sequence "1"\
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer0.daisycon.sbc.andreasfurster.nl \
  --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA 

switchIdentity "Tweakers" 8051

printSeparator "Install chaincode on Tweakers"
peer lifecycle chaincode install ./generated/chaincode-packages/mycc.tar.gz
peer lifecycle chaincode queryinstalled

printSeparator "Approve chaincode on Tweakers"
peer lifecycle chaincode approveformyorg \
  --channelID apchannel \
  --name mycc_1 \
  --version "1.0" \
  --sequence "1"\
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer0.daisycon.sbc.andreasfurster.nl \
  --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA 


switchIdentity "Coolblue" 7051

printSeparator "Check commit readiness (both orgs should be true)"
peer lifecycle chaincode checkcommitreadiness \
  --channelID apchannel \
  --name mycc_1 \
  --version "1.0" \
  --sequence "1"

printSeparator "Commit chaincode"
peer lifecycle chaincode commit \
  --channelID apchannel \
  --name mycc_1 \
  --version "1.0" \
  --sequence "1" \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE \
  --orderer localhost:7050 \
  --ordererTLSHostnameOverride orderer0.daisycon.sbc.andreasfurster.nl \
  --tls $CORE_PEER_TLS_ENABLED \
  --cafile $ORDERER_CA 

printSeparator "Query comitted chaincodes"
peer lifecycle chaincode querycommitted \
  --channelID apchannel

printSeparator "Run the API within Docker Containers"
cd ./application
docker-compose up
