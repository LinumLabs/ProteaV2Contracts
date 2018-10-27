pragma solidity ^0.4.24;

import "./RewardIssuerInterface.sol";
import "./ERC223/ERC223Receiver.sol";

contract EventManager is RewardIssuerInterface, ERC223Receiver {
    address public tokenManager;
    // States:
    // 0: Not registered
    // 1: RSVP'd
    // 99: Attended (Rewardable)
  
    struct EventData{
        string name;
        string date;
        string location;
        uint24 participantLimit;
        uint8 state;        
        // 0: Not created
        // 1: Created
        // 2: Concluded
        // 3: Cancelled
        uint256 requiredStake;
    }

    mapping(uint256 => EventData) public events;


    event EventCreated(uint256 indexed index, address publisher, string name);
    event EventConcluded(uint256 indexed index, address publisher, string name);

    constructor () public {
        
    }

    function createEvent(string name, string date, string location, uint24 participantLimit, uint256 requiredStake) internal {

    }

    function rsvp(address _user) internal {
        /// Send stake to reward manager
        /// Updated state
    }


    // 2 kinds of request with stake 
    // 1. Create, which has all the event info and the creation stake
    // 2. an event index and the required stake
    function tokenFallback(address _from, uint _value, bytes _data) external onlyToken {
        // Option 1
        address(this).call(_data);
    }

    function decodeStruct(EventData _event) private pure returns (EventData) {
        return _event;
    }

    

    // function exactEventStructFromBytes(bytes data) private returns (ExactUserStruct u)
    // {
    //     for (uint i=0;i<4;i++)
    //     {
    //         uint32 temp = uint32(data[i]);
    //         temp<<=8*i;
    //         u.id^=temp;
    //     }

    //     bytes memory str = new bytes(data.length-4);

    //     for (i=0;i<data.length-4;i++)
    //     {
    //         str[i]=data[i+4];
    //     }

    //     u.name=string(str);
    //  }


    modifier onlyToken(){
        require(msg.sender == address(tokenManager), "Not registered token address");
        _;
    }

}

/*
    This contract diverts stake to the reward manager, sets up a user in a standardised struct

    rewardable = 99

    The reward manager if it finds in the user mapping state = 99 it allows payment, the amount being a standardised function that returns a uint


    Calculating the reward in relation to attendance rate is done in that function
*/