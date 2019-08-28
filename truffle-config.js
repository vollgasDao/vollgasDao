require('dotenv').config();
const HDWalletProvider = require('truffle-hdwallet-provider')

const MNEMONIC = process.env["MNEMONIC"];
const INFURA_KEY_RINKEBY = process.env.INFURA_KEY_RINKEBY;
const RPC_URL = `https://rinkeby.infura.io/${INFURA_KEY_RINKEBY}`;
console.log(RPC_URL);


module.exports = {
  networks: {
    cldev: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*'
    },
    live: {
      provider: () => {
        return new HDWalletProvider(MNEMONIC, RPC_URL)
      },
      network_id: '*',
      // Necessary due to https://github.com/trufflesuite/truffle/issues/1971
      // Should be fixed in Truffle 5.0.17
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: '0.4.24'
    }
  }
}
