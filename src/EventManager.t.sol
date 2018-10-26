pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./EventManager.sol";

contract EventManagerTest is DSTest {
    EventManager contracts;

    function setUp() public {
        contracts = new EventManager();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
