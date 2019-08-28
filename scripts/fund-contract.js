let GasFutures = artifacts.require('GasFutures')
let LinkToken = artifacts.require('LinkToken')

/*
  This script is meant to assist with funding the requesting
  contract with LINK. It will send 3 LINK to the requesting
  contract for ease-of-use. Any extra LINK present on the contract
  can be retrieved by calling the withdrawLink() function.
*/

const payment = '2000000000000000000'

module.exports = async (callback) => {
  let gasFutures = await GasFutures.deployed()
  let tokenAddress = await gasFutures.getChainlinkToken()
  let token = await LinkToken.at(tokenAddress)
  console.log('Funding contract:', gasFutures.address)
  let tx = await token.transfer(gasFutures.address, payment)
  callback(tx.tx)
}
