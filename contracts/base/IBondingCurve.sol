pragma solidity 0.4.24;

/// @title  BondingCurvedToken - A bonding curve
///         implementation that is backed by an ERC20 token.
interface IBondingCurve {
    function pay() external payable;
}