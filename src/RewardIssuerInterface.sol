pragma solidity ^0.4.24;

contract RewardIssuerInterface {
    /// For a reward to be issued, user state must be set to 99, meaning "Rewardable" this is to be considered the final state of users in issuer contracts
    mapping(address => uint8) public memberState;

    function payout() public returns(uint256);
}