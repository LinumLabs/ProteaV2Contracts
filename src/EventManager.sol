pragma solidity ^0.4.24;

contract EventManager {
    // Standardised so possible other tools can have additional variables
    struct Member {
        uint state;
    }

    mapping(address => Member) public members;

    constructor () public {
        
    }

    
}

/*
    This contract diverts stake to the reward manager, sets up a user in a standardised struct

    rewardable = 99

    The reward manager if it finds in the user mapping state = 99 it allows payment, the amount being a standardised function that returns a uint


    Calculating the reward in relation to attendance rate is done in that function
*/