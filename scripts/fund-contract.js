let RinkebyGasStation = artifacts.require('RinkebyGasStation')
let LinkToken = artifacts.require('LinkToken')

/*
  This script is meant to assist with funding the requesting
  contract with LINK. It will send 3 LINK to the requesting
  contract for ease-of-use. Any extra LINK present on the contract
  can be retrieved by calling the withdrawLink() function.
*/

const payment = '3000000000000000000'

module.exports = async (callback) => {
  let rgs = await RinkebyGasStation.deployed()
  let tokenAddress = await rgs.getChainlinkToken()
  let token = await LinkToken.at(tokenAddress)
  console.log('Funding contract:', rgs.address)
  let tx = await token.transfer(rgs.address, payment)
  callback(tx.tx)
}
