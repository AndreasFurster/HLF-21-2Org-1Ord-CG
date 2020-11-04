const { Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const path = require('path');
const { buildCAClient, registerAndEnrollUser, enrollAdmin } = require(path.resolve(__dirname, 'CAUtil.js'));
const { buildCCPOrg1, buildWallet } = require(path.resolve(__dirname, 'AppUtil.js'));
const appDir = path.dirname(require.main.filename);

module.exports = async () => {
  // build an in memory object with the network configuration (also known as a connection profile)
  const ccp = buildCCPOrg1();

  // build an instance of the fabric ca services client based on
  // the information in the network configuration
  const caClient = buildCAClient(FabricCAServices, ccp, process.env.ORG1_CA_NAME);

  // setup the wallet to hold the credentials of the application user
  const wallet = await buildWallet(Wallets, path.resolve(appDir, process.env.WALLET_PATH));

  // in a real application this would be done on an administrative flow, and only once
  await enrollAdmin(caClient, wallet, process.env.MSP_ORG1);

  // in a real application this would be done only when a new user was required to be added
  // and would be part of an administrative flow
  await registerAndEnrollUser(caClient, wallet, process.env.MSP_ORG1, process.env.ORG1_USER_ID, 'org1.department1');

  // Create a new gateway instance for interacting with the fabric network.
  // In a real application this would be done as the backend server session is setup for
  // a user that has been verified.
  const gateway = new Gateway();


  // setup the gateway instance
  // The user will now be able to create connections to the fabric network and be able to
  // submit transactions and query. All transactions submitted by this gateway will be
  // signed by this user using the credentials stored in the wallet.
  await gateway.connect(ccp, {
    wallet,
    identity: process.env.ORG1_USER_ID,
    discovery: { enabled: true, asLocalhost: true } // using asLocalhost as this gateway is using a fabric network deployed locally
  });

  // Build a network instance based on the channel where the smart contract is deployed
  const network = await gateway.getNetwork(process.env.CHANNEL_NAME);

  // Get the contract from the network.
  const contract = network.getContract(process.env.CHAINCODE_NAME);

  return contract;
}