pragma solidity ^0.5.0;

// Imports:
import './base/ERC721/Future.sol';
import './base/Ownable.sol';

contract gasFutures is Future, Ownable {

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
    uint256 public dividendPool;
    // ******* ETH Pools END *******

    // ******* DAO policies *******
    uint256 public feePerGas;
    uint256 public dividendPoolRatio;
    uint256 public constant expirationDate = 28 days;
    // ******* DAO policies END *******

    // ******* ERC721 token id =>  Gas Future Contract *******
    mapping(uint256 => GasFuture) public gasFutures;
    // ******* ERC721 token id =>  Gas Future Contract *******

    // ******* redeemPrice (Chainlink -> EthGasStation) *******
    uint256 redeemPricePerGas;
    // ******* redeemPrice (Chainlink -> EthGasStation) END *******
    // **************************** State Variables END **********************************


    // Fallback function needed for arbitrary funding additions to Gelato Core's balance by owner
    function() external payable {
        require(isOwner(),
            "fallback function: only the owner should send ether to gasFutures without selecting a payable function."
        );
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
        // Step1.1: Zero value preventions
        require(_gasAmount != 0, "gasFutures.mintGasFuture: _gasAmount cannot be 0");

        // Step2: Require that interface transfers the correct execution prepayment
        require(msg.value == calcGasFuturePrice(),  // calc for msg.sender==dappInterface
            "gasFutures.mintGasFuture: msg.value != calcGasFuturePrice() for msg.sender/dappInterface"
        );

        // Step3: Instantiate GasFuture (in memory)
        GasFuture memory gasFuture = GasFuture(
            _gasAmount,
            expirationDate
        );

        // ****** Step4: Mint new GasFuture ERC721 token ******
        // Increment the current token id
        Counters.increment(_gasFutureIds);
        // Get a new, unique token id for the newly minted ERC721
        uint256 gasFutureId = _gasFutureIds.current();
        // Mint new ERC721 Token representing one childOrder
        _mint(msg.sender, gasFutureId);
        // ****** Step4: Mint new GasFuture ERC721 token END ******


        // Step5: gasFutures tracking state variable update
        // ERC721(gasFutureId) => GasFuture(struct)
        gasFutures[gasFutureId] = gasFuture;
    }
    // **************************** mintGasFuture() END ******************************


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

        // EFFECTS: emit event, then burn and delete the GasFuture struct - possible gas payout to msg.sender?
        _burn(_gasFutureId);
        delete gasFutures[_gasFutureId];

        // INTERACTIONS: payout the prepaidFee to the GasFuture owner
        gasFutureOwner.transfer(payout);
    }
    // **************************** redeemGasFuture() END ******************************



    /*
     * Liquidity Provider Functions
     */

    // deposit ETH

    // withdraw ETH

    // vote on premium rate

    // vote on gas rate




    /*
     * Gas Contract Functions
     */

    // Buy contract


    // Settle contract


    // Settle contract wrapped


    // Transfer contract // ERC721

}