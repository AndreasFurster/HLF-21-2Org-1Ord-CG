GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NO_COLOR='\033[0m'

function switchIdentity() {
    ORG=$1
    LOWER_MSP=$(echo $ORG | tr A-Z a-z)
    PORT=$2

    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA=${PWD}/generated/crypto-material/ordererOrganizations/daisycon.sbc.andreasfurster.nl/orderers/orderer0.daisycon.sbc.andreasfurster.nl/msp/tlscacerts/tlsca.daisycon.sbc.andreasfurster.nl-cert.pem
    export CORE_PEER_LOCALMSPID=${ORG}MSP
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/generated/crypto-material/peerOrganizations/${LOWER_MSP}.sbc.andreasfurster.nl/peers/peer0.${LOWER_MSP}.sbc.andreasfurster.nl/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/generated/crypto-material/peerOrganizations/${LOWER_MSP}.sbc.andreasfurster.nl/users/Admin@${LOWER_MSP}.sbc.andreasfurster.nl/msp
    export CORE_PEER_ADDRESS=localhost:${PORT}

    echoCurrentFabricEnvironment
}

function echoCurrentFabricEnvironment() {
    echo -e "${YELLOW}CORE_PEER_TLS_ENABLED=${CORE_PEER_TLS_ENABLED}"
    echo -e "ORDERER_CA=${ORDERER_CA}"
    echo -e "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
    echo -e "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"
    echo -e "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
    echo -e "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}${NO_COLOR}"
}

function printSeparator() {
    echo -e "${GREEN}"
    echo -e "▶ $1 \033[0m"
}
