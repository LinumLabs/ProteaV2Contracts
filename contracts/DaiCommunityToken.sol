pragma solidity ^0.4.24;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}


interface ERC223Receiver { 
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
        return size > 0;
    }

}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}


contract CommunityToken  {
    using SafeMath for uint256;
    using AddressUtils for address;
    
    address public rewardManager;
    uint256 public rewardPotTax;
    uint256 public poolBalance;
    ERC20Basic public reserveToken;

    uint256 internal totalSupply_;

    uint256 constant private PRECISION = 10000000000;
    string public name;
    string public symbol;
    uint8 public exponent;
    uint8 public decimals = 18;

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


    constructor(
        address _rewardManager,
        uint8 _rewardPotTax,
        string _name,
        uint8 _decimals,
        string _symbol,
        uint8 _exponent,
        address _reserveToken
    ) public {

        rewardManager = _rewardManager;
        rewardPotTax = _rewardPotTax;

        name = _name;
        decimals = _decimals;
        symbol = _symbol;
        exponent = _exponent;
        reserveToken = ERC20Basic(_reserveToken);

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
    

    /// @dev        Calculate the integral from 0 to t
    /// @param t    The number to integrate to
    function curveIntegral(uint256 t) internal view returns (uint256) {
        uint256 nexp = exponent + 1;
        // Calculate integral of t^exponent
        return PRECISION.div(nexp).mul(t ** nexp).div(PRECISION);
    }

    function priceToMint(uint256 numTokens) public view returns(uint256) {
        return curveIntegral(totalSupply_.add(numTokens)).sub(poolBalance);
    }

    function rewardForBurn(uint256 numTokens) public view returns(uint256) {
        return poolBalance.sub(curveIntegral(totalSupply_.sub(numTokens)));
    }

    /// Protea modifications
    /// @dev                Calculate the Community Added Tax(CAT) for funding the particiaption rewards
    /// @param numTokens    The number of tokens you want to mint
    function purchaseTax(uint256 numTokens) public view returns(uint256) {
        return numTokens.mul(rewardPotTax).div(100);
    }

    /// @dev                Burn tokens to receive ether
    /// @param numTokens    The number of tokens that you want to burn
    function burn(uint256 numTokens) public {
        require(balances[msg.sender] >= numTokens);

        uint256 reserveTokensToReturn = rewardForBurn(numTokens);
        totalSupply_ = totalSupply_.sub(numTokens);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        poolBalance = poolBalance.sub(reserveTokensToReturn);
        reserveToken.transfer(msg.sender, reserveTokensToReturn);

        emit Burned(numTokens, reserveTokensToReturn);
    }

    /// @dev                Mint new tokens with ether
    /// @param numTokens    The number of tokens you want to mint
    /// Notes: We have modified the minting function to tax the purchase tokens
    /// This behaves as a sort of stake on buyers to participate even at a small scale
    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(reserveToken.transferFrom(msg.sender, this, priceForTokens));

        totalSupply_ = totalSupply_.add(numTokens);
        // Calculating the community tax
        uint256 communityTax = purchaseTax(numTokens);
        balances[msg.sender] = balances[msg.sender].add(numTokens.sub(communityTax));
        // Here we add the tax to the community pot
        balances[rewardManager] = balances[rewardManager].add(communityTax);

        poolBalance = poolBalance.add(priceForTokens);

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
