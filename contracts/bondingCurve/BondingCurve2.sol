pragma solidity ^0.5.7;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./ICurveLogic.sol";

/// @title A bonding curve implementation for buying a selling bonding curve tokens.
/// @author dOrg
/// @notice Uses a defined ERC20 token as reserve currency
contract BondingCurve is Initializable, OpenZeppelinUpgradesOwnable, DividendPayingToken {
    using SafeMath for uint256;

    // IERC20 internal _collateralToken;
    // DividendPayingToken public _bondedToken;

    ICurveLogic internal _buyCurve;
    // ICurveLogic internal _sellCurve;
    address payable internal _beneficiary;

    uint256 internal _reserveBalance;
    uint256 internal _splitOnPay;

    uint256 private constant MAX_PERCENTAGE = 100;
    uint256 private constant MICRO_PAYMENT_THRESHOLD = 100;

    string internal constant TRANSFER_FROM_FAILED = "Transfer of collateralTokens from sender failed";
    string internal constant TOKEN_MINTING_FAILED = "bondedToken minting failed";
    string internal constant TRANSFER_TO_BENEFICIARY_FAILED = "Tranfer of collateralTokens to beneficiary failed";
    string internal constant INSUFFICENT_TOKENS = "Insufficent tokens";
    string internal constant MAX_PRICE_EXCEEDED = "Current price exceedes maximum specified";
    string internal constant PRICE_BELOW_MIN = "Current price is below minimum specified";
    string internal constant REQUIRE_NON_ZERO_NUM_TOKENS = "Must send a non zero amount of ETH";
    string internal constant SELL_CURVE_LARGER = "Buy curve value must be greater than Sell curve value";
    string internal constant SPLIT_ON_PAY_INVALID = "splitOnPay must be a valid percentage";
    string internal constant SPLIT_ON_PAY_MATH_ERROR = "splitOnPay splits returned a greater token value than input value";
    string internal constant NO_MICRO_PAYMENTS = "Payment amount must be greater than 100 'units' for calculations to work correctly";
    string internal constant TOKEN_BURN_FAILED = "bondedToken burn failed";
    string internal constant TRANSFER_TO_RECIPIENT_FAILED = "Transfer to recipient failed";


    event BeneficiarySet(address beneficiary);

    event Buy(address indexed buyer, address indexed recipient, uint256 amount, uint256 price, uint256 reserveAmount, uint256 beneficiaryAmount);
    event Sell(address indexed seller, address indexed recipient, uint256 amount, uint256 reward);
    event Pay(address indexed from, uint256 dividendAmount);

    constructor () public OpenZeppelinUpgradesOwnable () {
    }

    /// @dev Initialize contract
    /// @param beneficiary Recieves a proportion of incoming tokens on buy() and pay() operations.
    /// @param buyCurve Curve logic for buy curve.
    function initialize(
        address payable beneficiary,
        ICurveLogic buyCurve
    ) public initializer
    {

        // Ownable.initialize(owner); => Already called in constructor of OpenZeppelinUpgradesOwnabl
        _beneficiary = beneficiary;
        emit BeneficiarySet(_beneficiary);

        _buyCurve = buyCurve;
        //_sellCurve = sellCurve;
        // Excahnged collateralTOken to Eth and bondedToken to DividendPayingToken
        //_bondedToken = bondedToken;
        // _collateralToken = collateralToken;
    }

    /// @notice             Get the price in ether to mint tokens
    /// @param numTokens    The number of tokens to calculate price for
    function priceToBuy(uint256 numTokens) public view returns (uint256) {
        return _buyCurve.calcMintPrice(totalSupply(), _reserveBalance, numTokens);
    }

    /// @notice             Get the reward in ether to burn tokens
    /// @param numTokens    The number of tokens to calculate reward for
    function rewardForSell(uint256 numTokens) public view returns (uint256) {
        uint256 rewardForSellAmount = _buyCurve.calcBurnReward(totalSupply(), _reserveBalance, numTokens);
        uint256 fee = rewardForSellAmount.mul(100 + 5).div(100);
        uint256 returnedRewardForSell = rewardForSellAmount.sub(fee);
        return returnedRewardForSell;
    }

    /// @dev                Buy a given number of bondedTokens with a number of collateralTokens determined by the current rate from the buy curve.
    /// @param numTokens    The number of bondedTokens to buy
    /// @param maxPrice     Maximum total price allowable to pay in collateralTokens. If zero, any price is allowed.
    /// @param recipient    Address to send the new bondedTokens to
    function buy(uint256 numTokens, uint256 maxPrice, address recipient)
        public
        payable
    {
        uint256 numEth = msg.value;
        require(numEth > 0, REQUIRE_NON_ZERO_NUM_TOKENS);
        require(numTokens > 0, REQUIRE_NON_ZERO_NUM_TOKENS);

        // How many tokens will the buyer receive
        uint256 buyPrice = priceToBuy(numTokens);

        if (maxPrice != 0) {
            require(buyPrice <= maxPrice, MAX_PRICE_EXCEEDED);
        }

        // Check if user sent enough eth
        require(numEth >= buyPrice, "Insufficient Eth sent");

        uint256 sellPrice = rewardForSell(numTokens);

        require(buyPrice > sellPrice, SELL_CURVE_LARGER);

        // Beneficiary will be DAO liquidity reserve
        uint256 ethToBeneficiary = buyPrice.sub(sellPrice);
        uint256 ethToReserve = sellPrice;

        _reserveBalance = _reserveBalance.add(ethToReserve);

        // Mint q = buyPrice tokens
        _mint(recipient, numTokens);

        // Distribute spread of bonding curves  to pool
        _beneficiary.transfer(ethToBeneficiary);

         // Refund user overpaid ETH
        if (msg.value > buyPrice)
        {
            msg.sender.transfer(msg.value.sub(buyPrice));
        }

        emit Buy(msg.sender, recipient, numEth, buyPrice, ethToReserve, ethToBeneficiary);
    }

    /// @dev                Sell a given number of bondedTokens for a number of collateralTokens determined by the current rate from the sell curve.
    /// @param numTokens    The number of bondedTokens to sell
    /// @param minPrice     Minimum total price allowable to receive in collateralTokens
    /// @param recipient    Address to send collateralTokens to

    function sell(uint256 numTokens, uint256 minPrice, address payable recipient)
        public {

        require(numTokens > 0, REQUIRE_NON_ZERO_NUM_TOKENS);
        require(balanceOf(msg.sender) >= numTokens, INSUFFICENT_TOKENS);

        uint256 burnReward = rewardForSell(numTokens);
        require(burnReward >= minPrice, PRICE_BELOW_MIN);

        _reserveBalance = _reserveBalance.sub(burnReward);

        _burn(msg.sender, numTokens);

        // Send Eth back to receipient
        recipient.transfer(burnReward);

        emit Sell(msg.sender, recipient, numTokens, burnReward);
    }


    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.

    function payCurve()
        public
        payable
    {
        distributeDividends();
        /*uint256 amount = msg.value;
        require(amount > MICRO_PAYMENT_THRESHOLD, NO_MICRO_PAYMENTS);
        require(totalSupply() > 0);

        if (amount > 0) {
          magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (amount).mul(magnitude) / totalSupply()
          );
          emit DividendsDistributed(msg.sender, amount);
        }

        emit Pay(msg.sender, amount);
        */
    }

    /*
        Admin Functions
    */

    /// @notice Set beneficiary to a new address
    /// @param beneficiary       New beneficiary
    function setBeneficiary(address payable beneficiary) public onlyOwner {
        _beneficiary = beneficiary;
        emit BeneficiarySet(_beneficiary);
    }

    /*
        Getter Functions
    */

    /// @notice Get reserve token contract
    /*
    function collateralToken() public view returns (IERC20) {
        return _collateralToken;
    }
    */



    /// @notice Get buy curve contract
    function buyCurve() public view returns (ICurveLogic) {
        return _buyCurve;
    }

    /// @notice Get sell curve contract
    /*
    function sellCurve() public view returns (ICurveLogic) {
        return _sellCurve;
    }
    */

    /// @notice Get beneficiary
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /// @notice Get reserve balance
    function reserveBalance() public view returns (uint256) {
        return _reserveBalance;
    }

    /// @notice Get split on pay parameter
    function splitOnPay() public view returns (uint256) {
        return _splitOnPay;
    }

    /// @notice Get dividend pool contract
    //function dividendPool() public view returns (DividendPool) {
    //    return _dividendPool;
    //}

    /// @notice Get minimum value accepted for payments
    function getPaymentThreshold() public view returns (uint256) {
        return MICRO_PAYMENT_THRESHOLD;
    }

    function() external payable
    {
        payCurve();
    }
}
