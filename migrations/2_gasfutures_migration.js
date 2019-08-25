let GasFutures = artifacts.require('GasFutures')
let LinkToken = artifacts.require('LinkToken')
let Oracle = artifacts.require('Oracle')

const BONDING_CURVE = "0x07a55B3F83ba614ff738fB547d54D1A8fd28333C";

module.exports = (deployer, network) => {
  // Local (development) networks need their own deployment of the LINK
  // token and the Oracle contract
  if (!network.startsWith('live')) {
    deployer.deploy(LinkToken).then(() => {
      return deployer.deploy(Oracle, LinkToken.address).then(() => {
        return deployer.deploy(GasFutures, BONDING_CURVE)
      })
    })
  } else {
    // For live networks, use the 0 address to allow the ChainlinkRegistry
    // contract automatically retrieve the correct address for you
    deployer.deploy(GasFutures, BONDING_CURVE)
  }
}
