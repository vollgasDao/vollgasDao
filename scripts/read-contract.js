let GasFutures = artifacts.require('GasFutures')

/*
  This script makes it easy to read the data variable
  of the requesting contract.
*/

module.exports = async (callback) => {
  let gasFutures = await GasFutures.deployed()
  let averageGasPrice = await gasFutures.redeemPricePerGas.call()
  callback(averageGasPrice)
}
