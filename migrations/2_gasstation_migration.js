let RinkebyGasStation = artifacts.require('RinkebyGasStation')
let LinkToken = artifacts.require('LinkToken')
let Oracle = artifacts.require('Oracle')

module.exports = (deployer, network) => {
  // Local (development) networks need their own deployment of the LINK
  // token and the Oracle contract
  if (!network.startsWith('live')) {
    deployer.deploy(LinkToken).then(() => {
      return deployer.deploy(Oracle, LinkToken.address).then(() => {
        return deployer.deploy(RinkebyGasStation)
      })
    })
  } else {
    // For live networks, use the 0 address to allow the ChainlinkRegistry
    // contract automatically retrieve the correct address for you
    deployer.deploy(RinkebyGasStation)
  }
}
