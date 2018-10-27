pragma solidity ^0.4.24;

import "./zeppelin-solidity/ERC20/ERC20Basic.sol";
import "./RewardIssuerInterface.sol";

contract RewardManager {
    address public tokenManager;
    mapping (address => bool) public approvedIssuer;

    mapping (address => uint256) public reputation;

    event RewardClaimed(address indexed account, uint256 amount);
    constructor() {

    }

    function reputationOf(address _account) public view returns(uint256) {
        return (reputation[_account]);
    }

    function initContract(address _tokenManager) public {
        tokenManager = _tokenManager;
    }

    function claimReward(address _issuer, uint256 _index) public {
        require(approvedIssuer[_issuer], "Moduled not authoried to reward");
        RewardIssuerInterface issuer = RewardIssuerInterface(_issuer);
        ERC20Basic token = ERC20Basic(tokenManager);
        uint256 payout = issuer.payout(msg.sender, _index);
        token.transfer(msg.sender, payout);    
        emit RewardClaimed(msg.sender, payout);
    }

}

/*
    This contract will manage the reward pot, issuing collateral backed tokens for participation based on the overall attendance rates of the meetup

    Authorised reward contracts will be in a mapping of address => boolean 

    Checks if user state is 99 then gets the reward amount from a reward function that always returns uint
 */ 