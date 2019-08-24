pragma solidity >=0.4.21 <0.6.0;

import "./ChainlinkClient.sol";

// RinkebyGasStation inherits the ChainlinkClient contract to gain the
// functionality of creating Chainlink requests
contract RinkebyGasStation is ChainlinkClient, Ownable {
  // Helper constant for testnets: 1 request = 1 LINK
  uint256 constant private ORACLE_PAYMENT = 1 * LINK;
  // Helper constant for the Chainlink uint256 multiplier JobID
  bytes32 constant UINT256_MUL_JOB = bytes32("6d1bfe27e7034b1d87b5270556b17277");

  // Stores the answer from the Chainlink oracle
  uint256 public gasFuturePrice;

  constructor() public {
    // Set the address for the LINK token for the network
    setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
    // Set the address of the oracle to create requests to
    setChainlinkOracle(0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e);
  }

  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  // Creates a Chainlink request with the uint256 multiplier job
  function requestAverageGasPrice()
    public
    onlyOwner
  {
    // newRequest takes a JobID, a callback address, and callback function as input
    Chainlink.Request memory req = buildChainlinkRequest(UINT256_MUL_JOB,
                                                         address(this),
                                                         this.setGasFuturePrice.selector
    );
    // Adds a URL with the key "get" to the request parameters
    req.add("get", "https://ethgasstation.info/json/ethgasAPI.json");
    // Uses input param (dot-delimited string) as the "path" in the request parameters
    req.add("path", "AVERAGE");
    // Adds an integer with the key "times" to the request parameters
    req.addInt("times", 1);
    // Sends the request with 1 LINK to the oracle contract
    sendChainlinkRequest(req, ORACLE_PAYMENT);
  }

  // fulfill receives a uint256 data type
  function setGasFuturePrice(bytes32 _requestId, uint256 _price)
    public
    // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
    recordChainlinkFulfillment(_requestId)
  {
    gasFuturePrice = _price;
  }

  // withdrawLink allows the owner to withdraw any extra LINK on the contract
  function withdrawLink()
    public
    onlyOwner
  {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  /**
   * @notice Call this method if no response is received within 5 minutes
   * @param _requestId The ID that was generated for the request to cancel
   * @param _payment The payment specified for the request to cancel
   * @param _callbackFunctionId The bytes4 callback function ID specified for
   * the request to cancel
   * @param _expiration The expiration generated for the request to cancel
   */
  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }
}