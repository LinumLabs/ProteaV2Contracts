pragma solidity ^0.4.24;

contract RewardManager {
    address public tokenManager;
    mapping (address => bool) public approvedIssuer;

    constructor() {

    }

    function initContract(address _tokenManager) public {
        tokenManager = _tokenManager;
    }

    function claimReward(address _issuer, uint256 _index) public {
        
    }
}

/*
    This contract will manage the reward pot, issuing collateral backed tokens for participation based on the overall attendance rates of the meetup

    Authorised reward contracts will be in a mapping of address => boolean 

    Checks if user state is 99 then gets the reward amount from a reward function that always returns uint
 */ 