pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./RewardManager.sol";

contract RewardManagerTest is DSTest {
    RewardManager contracts;

    function setUp() public {
        contracts = new RewardManager();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
