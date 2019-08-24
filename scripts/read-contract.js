let RinkebyGasStation = artifacts.require('RinkebyGasStation')

/*
  This script makes it easy to read the data variable
  of the requesting contract.
*/

module.exports = async (callback) => {
  let rgs = await RinkebyGasStation.deployed()
  let averageGasPrice = await rgs.averageGasPrice.call()
  callback(averageGasPrice)
}
