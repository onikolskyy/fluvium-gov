
const dotenv = require('dotenv')
const result = dotenv.config()

if (result.error) {
  throw result.error
}


const HDWalletProvider = require('@truffle/hdwallet-provider');
module.exports = {
  networks: {
    ganache: {
      host:"localhost",
      port: 8545,
      network_id: "*"
    },
    matic: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC,
      `https://rpc-mumbai.maticvigil.com/v1/54d417657d0ad68eb6efca99b0fbbce1b099e141`),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      gas: 6000000,
      gasPrice: 10,
    },
    goerli: {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, 'wss://eth-goerli.alchemyapi.io/v2/pNVs9VSXQoOWRWcS7roK6Qwa49UN23bz')},
      network_id: '*' // eslint-disable-line camelcase
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
       version: "0.7.6",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 200
       },
      //  evmVersion: "byzantium"
       }
    }
  },

};
