pragma solidity ^0.4.24;

import "./ERC223/ERC223Receiver.sol";
import "./zeppelin-solidity/AddressUtils.sol";
import "./zeppelin-solidity/SafeMath.sol";

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC223StandardToken  {
    using SafeMath for uint256;
    using AddressUtils for address;
    
    address public rewardManager;
    uint256 public rewardPotTax;
    uint256 public poolBalance;

    uint256 internal totalSupply_;

    // uint256 constant private PRECISION = 10000000000;
    string public name;
    string public symbol;
    uint8 public exponent;
    uint32 public slope;
    uint8 public decimals = 18;
    bool initalized = false;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;

    event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint value);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    event Minted(uint256 amount, uint256 totalCost);
    event Burned(uint256 amount, uint256 reward);

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

    struct Multihash {
        bytes32 hash;
        uint8 hash_function;
        uint8 size;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
     )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
      public
      returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
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

    /// @dev                Burn tokens to receive ether
    /// @param numTokens    The number of tokens that you want to burn
    function burn(uint256 numTokens) public {
        require(balances[msg.sender] >= numTokens);

        uint256 ethToReturn = rewardForBurn(numTokens);
        totalSupply_ = totalSupply_.sub(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        poolBalance = poolBalance.sub(ethToReturn);
        msg.sender.transfer(ethToReturn);

        emit Burned(numTokens, ethToReturn);
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
}
