pragma solidity ^0.4.24;

import "../zeppelin-solidity/ERC20/StandardToken.sol";

contract ERC223StandardToken is StandardToken{
    function transfer(address to, uint value, bytes data) public;
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}