pragma solidity ^0.4.24;

import "./zeppelin-solidity/SafeMath.sol";
import "./RewardIssuerInterface.sol";
import "./ERC223/ERC223Receiver.sol";
import "./zeppelin-solidity/ERC20/ERC20Basic.sol";

contract EventManager is RewardIssuerInterface, ERC223Receiver {
    using SafeMath for uint256;
    address public tokenManager;
    address public rewardManager;

    uint256 public creationCost;
    uint256 public maxAttendanceBonus;

    /// For a reward to be issued, user state must be set to 99, meaning "Rewardable" this is to be considered the final state of users in issuer contracts
    mapping(uint256 => mapping(address => uint8)) public memberState;
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
        uint24 registered;
        uint24 attended;
        address organiser;
        // 0: Not created
        // 1: Created
        // 2: Concluded
        // 3: Cancelled
        uint256 requiredStake;
        uint256 totalStaked;
        uint256 payout;
    }

    mapping(uint256 => EventData) public events;
    
    uint256 public numberOfEvents = 0;

    event EventCreated(uint256 indexed index, address publisher);
    event EventConcluded(uint256 indexed index, address publisher, uint8 state);

    event MemberRegistered(uint256 indexed index, address member);
    event MemberAttended(uint256 indexed index, address member);

    constructor () public {
        
    }

    function createEvent(
        string _name, string _date, string _location, 
        uint24 _participantLimit, address _organiser, uint256 _requiredStake) 
        private {
        require(forwardStake(creationCost, _organiser), "Must forward funds to the reward manager");
        numberOfEvents += 1;
        events[numberOfEvents].name = _name;
        events[numberOfEvents].date = _date;
        events[numberOfEvents].location = _location;
        events[numberOfEvents].participantLimit = _participantLimit;
        events[numberOfEvents].organiser = _organiser;
        events[numberOfEvents].requiredStake = _requiredStake;
        emit EventCreated(numberOfEvents, _organiser);
    }

    function endEvent(uint256 _index) public onlyManager(_index){
        require(events[_index].state == 1, "Event not active");
        events[_index].state = 2;
        calcPayout(_index);
        emit EventConcluded(_index, msg.sender, events[_index].state);
    }

    function cancelEvent(uint256 _index) public onlyManager(_index){
        require(events[_index].state == 1, "Event not active");
        events[_index].state = 3;
        emit EventConcluded(_index, msg.sender, events[_index].state);
    }

    function forwardStake(uint256 _amount, address _member) internal returns(bool) {
        ERC20Basic token = ERC20Basic(tokenManager);
        token.transfer(_member, _amount);    
        return true;
    }

    function rsvp(uint256 _index, address _member) private {
        require(forwardStake(events[_index].requiredStake, _member), "Must forward funds to the reward manager");
        /// Send stake to reward manager
        /// Updated state
        memberState[_index][_member] = 1;
        events[_index].totalStaked.add(events[_index].requiredStake);
        events[_index].registered += 1;
        emit MemberRegistered(_index, _member);
    }

   

    // 2 kinds of request with stake 
    // 1. Create, which has all the event info and the creation stake
    // 2. an event index and the required stake
    function tokenFallback(address _from, uint _value, bytes _data) external onlyToken {
        // Option 1
        address(this).call(_data);
    }

    function calcPayout(uint256 _index) internal {
        uint256 reward = events[_index].totalStaked / events[_index].attended; 
        events[_index].payout = reward.add(maxAttendanceBonus.mul(events[_index].attended).div(events[_index].participantLimit));
    }

    function payout(address _member, uint256 _index) external view onlyRewardManager onlyMember(_member, _index) returns(uint256){
        require(memberState[_index][_member] == 99, "User not attended");
        if(events[_index].state == 3){
            return events[_index].requiredStake;
        } else if(events[_index].state == 3) {
            return events[_index].payout;
        }
        return 0;
    }
    
    modifier onlyMember(address _member, uint256 _index){
        require(memberState[_index][_member] >= 1, "User not registered");
        _;
    }

    modifier onlyToken(){
        require(msg.sender == address(tokenManager), "Not registered token address");
        _;
    }

    modifier onlyRewardManager() {
        require(msg.sender == rewardManager, "Only reward manager authorised");
        _;
    }

    modifier onlyManager(uint256 _index){
        require(events[_index].organiser == msg.sender, "Account not organiser");
        _;
    }

}

/*
    This contract diverts stake to the reward manager, sets up a user in a standardised struct

    rewardable = 99

    The reward manager if it finds in the user mapping state = 99 it allows payment, the amount being a standardised function that returns a uint


    Calculating the reward in relation to attendance rate is done in that function
*/