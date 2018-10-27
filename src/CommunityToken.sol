pragma solidity ^0.4.24;

import "./zeppelin-solidity/SafeMath.sol";
import "./zeppelin-solidity/ERC20/StandardToken.sol";
import "./Relevant-Bonding-Curves/EthBondingCurvedToken.sol";
import "./ERC223/ERC223Receiver.sol";
import "./zeppelin-solidity/AddressUtils.sol";

contract CommunityToken is EthBondingCurvedToken {
    address public rewardManager;
    uint256 public rewardPotTax;
    using AddressUtils for address;

    event Transfer(address indexed from, address indexed to, uint value, bytes data);
    

    // uint256 constant private PRECISION = 10000000000;
    string public name;
    string public symbol;
    uint8 public exponent;
    uint32 public slope;
    uint8 public decimals = 18;
    bool initalized = false;

    struct Multihash {
        bytes32 hash;
        uint8 hash_function;
        uint8 size;
    }

    // Multihash public imageHash;

    // @dev constructor        Initializes the bonding curve
    // constructor() public {
    // }

    // @dev initContract        Initializes the bonding curve
    // need to make sure this function is only called once
    // @param _name             The name of the token
    // @param _decimals         The number of decimals to use
    // @param _symbol           The symbol of the token
    // @param _exponent         The exponent of the curve
    // @param _hash             digest produced by hashing content using hash function
    // @param _hashFunction     code for the hash function used
    // @param _size             length of the digest
    function initContract(
        address _rewardManager,
        uint8 _rewardPotTax,
        string _name,
        uint8 _decimals,
        string _symbol,
        uint8 _exponent,
        uint32 _slope,
        bytes32 _hash,
        uint8 _hashFunction,
        uint8 _size
    ) public payable {
        require(!initalized);
        // extra precautions
        require(poolBalance == 0 && totalSupply_ == 0);
        initalized = false;
        
        rewardManager = _rewardManager;
        rewardPotTax = _rewardPotTax;

        name = _name;
        decimals = _decimals;
        symbol = _symbol;
        exponent = _exponent;
        slope = _slope;

        // don't actually need to do this - can store in logs!
        // imageHash = Multihash(_hash, _hashFunction, _size);
        emit StoreHash(_hash, _hashFunction, _size);
    }

    // @dev Add comment
    // @param _hash             digest produced by hashing content using hash function
    // @param _hashFunction     code for the hash function used
    // @param _size             length of the digest
    function addComment(
        bytes32 _hash,
        uint8 _hashFunction,
        uint8 _size
    ) public {
        emit CommentLog(_hash, _hashFunction, _size, msg.sender);
    }

    /// @dev        Calculate the integral from 0 to t
    /// @param t    The number to integrate to
    function curveIntegral(uint256 t) internal returns (uint256) {
        uint256 nexp = exponent + 1;
        return (t ** nexp).div(nexp).div(slope).div((10 ** (uint256(decimals) * uint256(exponent))));
    }

    function priceToMint(uint256 numTokens) public returns(uint256) {
        return curveIntegral(totalSupply_.add(numTokens)).sub(poolBalance);
    }

    function rewardForBurn(uint256 numTokens) public returns(uint256) {
        return poolBalance.sub(curveIntegral(totalSupply_.sub(numTokens)));
    }

    /// Protea modifications
    /// @dev                Calculate the Community Added Tax(CAT) for funding the particiaption rewards
    /// @param numTokens    The number of tokens you want to mint
    function purchaseTax(uint256 numTokens) public returns(uint256) {
        return numTokens.mul(rewardPotTax).div(100);
    }

    /// @dev                Mint new tokens with ether
    /// @param numTokens    The number of tokens you want to mint
    /// Notes: We have modified the minting function to tax the purchase tokens
    /// This behaves as a sort of stake on buyers to participate even at a small scale
    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(msg.value >= priceForTokens);

        totalSupply_ = totalSupply_.add(numTokens);
        // Calculating the community tax
        uint256 communityTax = purchaseTax(numTokens);
        balances[msg.sender] = balances[msg.sender].add(numTokens.sub(communityTax));
        // Here we add the tax to the community pot
        balances[rewardManager] = balances[rewardManager].add(communityTax);

        poolBalance = poolBalance.add(priceForTokens);
        if (msg.value > priceForTokens) {
            msg.sender.transfer(msg.value - priceForTokens);
        }

        emit Minted(numTokens, priceForTokens);
    }

    function transfer(address _to, uint _value, bytes _data) public {
        require(_value > 0, "Transfer amount invalid");
        if(_to.isContract()) {
            ERC223Receiver receiver = ERC223Receiver(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
    }


    /// End Protea modifications


    /// Really dont like this but until we can build the bytes in Web3 we need it in here
    // struct EventData{
    //     string name;
    //     string date;
    //     string location;
    //     uint24 participantLimit;
    //     uint8 state;        
    //     // 0: Not created
    //     // 1: Created
    //     // 2: Concluded
    //     // 3: Cancelled
    //     uint256 requiredStake;
    // }
    // function exactEventStructToBytes(ExactUserStruct u) private
    // returns (bytes data)
    // {
    //     // _size = "sizeof" u.id + "sizeof" u.name
    //     uint _size = 4 + bytes(u.name).length;
    //     bytes memory _data = new bytes(_size);

    //     uint counter=0;
    //     for (uint i=0;i<4;i++)
    //     {
    //         _data[counter]=byte(u.id>>(8*i)&uint32(255));
    //         counter++;
    //     }

    //     for (i=0;i<bytes(u.name).length;i++)
    //     {
    //         _data[counter]=bytes(u.name)[i];
    //         counter++;
    //     }

    //     return (_data);
    // }


    event CommentLog (
        bytes32 hash,
        uint8 hashFunction,
        uint8 size,
        address account
    );

    event StoreHash (
        bytes32 hash,
        uint8 hashFunction,
        uint8 size
    );
}