const HDWalletProvider = require('truffle-hdwallet-provider')

const MNEMONIC = "ask settle radar stove person document recipe alien expose similar frost gasp";
const RPC_URL = "https://ropsten.infura.io/v3/b23fadbe7aa24194bc8bc9d86498eb38";


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
