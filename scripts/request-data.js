let GasFutures = artifacts.require("GasFutures");

/*
  This script allows for a Chainlink request to be created from
  the requesting contract. Defaults to the Chainlink oracle address
  on this page: https://docs.chain.link/docs/testnet-oracles
*/

module.exports = async callback => {
  let gasFutures = await GasFutures.deployed();
  console.log("Creating request on contract:", gasFutures.address);
  let tx = await gasFutures.requestAverageGasPrice();
  callback(tx.tx);
};
