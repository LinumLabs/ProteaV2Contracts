pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./ExchangeManager.sol";

contract ExchangeManagerTest is DSTest {
    ExchangeManager contracts;

    function setUp() public {
        contracts = new ExchangeManager();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
