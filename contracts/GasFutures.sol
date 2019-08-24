pragma solidity >=0.4.21 <0.6.0;

// Imports:
import './base/ERC721/Future.sol';
import "./base/ChainlinkClient.sol";

contract GasFutures is ChainlinkClient, Future, Ownable {

    // Libraries inherited from Future:
    // using Counters for Counters.Counter;

    // Counter for execution Claims
    Counters.Counter private _gasFutureIds;

    // Gas Future Object
    struct GasFuture {
        uint256 gasAmount;
        uint256 expirationDate;
    }

    // **************************** State Variables **********************************
    // ******* ETH Pools *******
    uint256 public reservePool;
    BondingCurve public bondingCurve;
    // ******* ETH Pools END *******

    // ******* DAO policies *******
    uint256 public feePerGas;
    uint256 public dividendPoolPercentage;
    uint256 public constant futureContractDuration = 28 days;
    // ******* DAO policies END *******

    // ******* ERC721 token id =>  Gas Future Contract *******
    mapping(uint256 => GasFuture) public gasFutures;
    // ******* ERC721 token id =>  Gas Future Contract *******



    // ******* CHAINLINK: redeemPricePerGas (Chainlink -> EthGasStation) *******
    // Helper constant for testnets: 1 request = 1 LINK
    uint256 constant private ORACLE_PAYMENT = 1 * LINK;
    // Helper constant for the Chainlink uint256 multiplier JobID
    bytes32 constant UINT256_MUL_JOB = bytes32("6d1bfe27e7034b1d87b5270556b17277");
    // Callback variable to be set:
    uint256 public redeemPricePerGas;
    // ******* CHAINLINK redeemPricePerGas (Chainlink -> EthGasStation) END *******
    // **************************** State Variables END **********************************

    // **************************** GasFutures constructor() ******************************
    constructor()
        public
    {
        // Initialise _feePerGas, dividendPoolPercentage
        feePerGas = 80000000000;  // 80 gwei
        dividendPoolPercentage = 5;  // 5%
        // Chainlink
        // Set the address for the LINK token for the network
        setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        // Set the address of the oracle to create requests to
        setChainlinkOracle(0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e);
    }
    // **************************** GasFuturesconstructor() END *****************************


    // Fallback function tops up reserve pool
    function() external payable {
        reservePool.add(msg.value);
    }

    // Function to calculate the price of the user's GasFuture contract
    function calcGasFuturePrice(uint256 _gasAmount)
        public
        view
        returns(uint256 gasFuturePrice)
    {
        // msg.sender == gasFuture buyer
        gasFuturePrice = _gasAmount.mul(feePerGas);
    }

    // CREATE
    // **************************** mintGasFuture() ******************************
    function mintGasFuture(uint256 _gasAmount)
        payable
        public
    {
        // Step0: Zero value preventions
        require(_gasAmount != 0, "gasFutures.mintGasFuture: _gasAmount cannot be 0");

        // Step1: get the gasFuturePrice
        uint256 gasFuturePrice = _gasAmount.mul(feePerGas);

        // Step2: Require that user transfers full gasFuturePrice ether
        require(msg.value == gasFuturePrice,  // calc for msg.sender==dappInterface
            "gasFutures.mintGasFuture: msg.value != calcGasFuturePrice() for msg.sender/dappInterface"
        );

        // Step3: Distribute GasFuturePrice into reserve and dividend pools
        uint256 dividendPoolShare = gasFuturePrice.mul(100 + dividendPoolPercentage).div(100);
        uint256 reservePoolShare = gasFuturePrice.sub(dividendPoolShare);
        bondingCurve.payCurve().value(dividendPoolShare);
        reservePool.add(reservePoolShare);


        // Step4: Instantiate GasFuture (in memory)
        GasFuture memory gasFuture = GasFuture(
            _gasAmount,
            now + futureContractDuration
        );

        // ****** Step5: Mint new GasFuture ERC721 token ******
        // Increment the current token id
        Counters.increment(_gasFutureIds);
        // Get a new, unique token id for the newly minted ERC721
        uint256 gasFutureId = _gasFutureIds.current();
        // Mint new ERC721 Token representing one childOrder
        _mint(msg.sender, gasFutureId);
        // ****** Step5: Mint new GasFuture ERC721 token END ******

        // Step6: gasFutures tracking state variable update
        // ERC721(gasFutureId) => GasFuture(struct)
        gasFutures[gasFutureId] = gasFuture;
    }
    // **************************** mintGasFuture() END ******************************


    // UPDATE via CHAINLINK RINKEBY
    // **************************** CHAINLINK ******************************]
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
                                                            this,
                                                            this.setRedeemPricePerGas.selector
        );
        // Adds a URL with the key "get" to the request parameters
        req.add("get", "https://ethgasstation.info/json/ethgasAPI.json");
        // Uses input param (dot-delimited string) as the "path" in the request parameters
        req.add("path", "average");
        // Adds an integer with the key "times" to the request parameters
        req.addInt("times", 1);
        // Sends the request with 1 LINK to the oracle contract
        sendChainlinkRequest(req, ORACLE_PAYMENT);
    }

    // fulfill receives a uint256 data type
    function setRedeemPricePerGas(bytes32 _requestId, uint256 _averagePrice)
        public
        // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
        recordChainlinkFulfillment(_requestId)
    {
        redeemPricePerGas = _averagePrice;
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
    // **************************** CHAINLINK END ******************************


    // DELETE
    // onlyGasFutureOwner
    modifier onlyGasFutureOwner(uint256 _gasFutureId) {
        require(msg.sender == ownerOf(_gasFutureId),
            "modifier onlyGasFutureOwner: msg.sender != ownerOf(gasFutureId)"
        );
        _;
    }
    // **************************** redeemGasFuture() ******************************
    function redeemGasFuture(uint256 _gasFutureId)
        onlyGasFutureOwner(_gasFutureId)
        external
    {
        GasFuture memory gasFuture = gasFutures[_gasFutureId];

        // Local variables needed for Checks, Effects -> Interactions pattern
        address payable gasFutureOwner = address(uint160(ownerOf(_gasFutureId)));
        uint256 payout = gasFuture.gasAmount.mul(redeemPricePerGas);

        // CHECKS: onlyGasFutureOwner modifier
        require(gasFuture.expirationDate > now,
            "GasFutures.redeemGasFuture: gasFuture.expirationDate passed"
        );
        require(reservePool >= payout,
            "GasFutures.redeemGasFuture: insufficient funds in reservePool"
        );

        // EFFECTS: emit event, then burn and delete the GasFuture struct - possible gas payout to msg.sender?
        _burn(_gasFutureId);
        delete gasFutures[_gasFutureId];

        // INTERACTIONS: payout the prepaidFee to the GasFuture owner
        gasFutureOwner.transfer(payout);
    }
    // **************************** redeemGasFuture() END ******************************


}