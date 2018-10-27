pragma solidity ^0.4.24;

contract RewardIssuerInterface {
    function payout(address _member, uint256 _index) public returns(uint256);
}