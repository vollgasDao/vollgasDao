pragma solidity ^0.5.0;

// Imports:
import "chainlink/contracts/Chainlinked.sol";
import './base/ERC721/Future.sol';
import './base/Ownable.sol';
import './base/SafeMath.sol';

contract GasFutures is ChainlinkClient, Future, Ownable {

    // Libraries inherited from Future:
    // using Counters for Counters.Counter;

    // Counter for execution Claims
    Counters.Counter private _gasFutureIds;

    // New Core struct
    struct GasFuture {
        address dappInterface;
        bytes functionSignature;
    }

    /*
     * State Variables
     */

    /// ETH Reserve
    uint256 dividendPool;
    /// DAO shares

    uint256 premium;
    uint256 dailyMultiplier;
    uint256 duration;
    // changeable through DAO

    uint256 currentGasPrice;
    // through chainlink oracle

    mapping(uint256 => address) public outstandingGasFuturesOwner;
    mapping(uint256 => bytes32) public outstandingGasFuturesData;    // expiryDate, gasAmount, gasPriceFT
    uint256 nonce;



    /*
     * GasFutures Functions
     */

    function buyGasFuture(
        uint256 gasAmount
    )
        public payable
        returns (uint256, uint256)
    {
        require(msg.value == gasAmount * currentGasPrice, "msg.value does not cover future cost");
        // consider premium -> use gasPriceFT instead of currentGasPrice?

        uint256 gasPriceFT = currentGasPrice * premium;
        // consider extracting the premium to dividend pool
        // change computation logic, just extract a flat fee instead of percentage

        uint256 expiryDate = block.number + duration;
        bytes32 gasFutureHash = keccak256(abi.encodePacked(expiryDate, gasAmount, gasPriceFT));
        nonce++;
        outstandingGasFuturesOwner[nonce] = msg.sender;
        outstandingGasFuturesData[nonce] = gasFutureHash;
        return (nonce, gasPriceFT);

        // consider not selling more futures than the reserve can handle?
    }

    function redeemGasFuture(
        uint256 gasFutureId,
        uint256 expiryDate,
        uint256 gasAmount,
        uint256 gasPriceFT
    )
        public
        returns (uint256)
    {
        require(block.number <= expiryDate, "GasFuture contract expired");

        bytes32 gasFutureHash = keccak256(abi.encodePacked(expiryDate, gasAmount, gasPriceFT));
        require(gasFutureHash == outstandingGasFuturesData[gasFutureId], "GasFuture data not valid");
        // can this be submitted by anyone??
        // this should be doable by the owner of the gasContract & delegated owners

        uint256 payout;
        if (currentGasPrice == gasPriceFT) {
            payout = gasAmount;
        } else if (currentGasPrice > gasPriceFT) {
            uint256 gasPriceDelta = currentGasPrice - gasPriceFT;
            payout = gasAmount + (gasAmount * gasPriceDelta);
        } else {
            uint256 gasPriceDelta = gasPriceFT - currentGasPrice;
            payout = gasAmount - (gasAmount * gasPriceDelta);
        }

        outstandingGasFuturesOwner[gasFutureId] = address(0);
        outstandingGasFuturesData[gasFutureId] = bytes32(0);
        // deletes GasFuture, returns gas from deleting storage, prevents re-entrancy

        msg.sender.transfer(payout);
        return(payout);     // necessary?
    }


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