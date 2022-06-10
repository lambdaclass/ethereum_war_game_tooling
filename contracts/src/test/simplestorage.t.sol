// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
import "../../lib/ds-test/src/test.sol";
import "../simplestorage.sol"; 
contract SimpleStorageTest is DSTest {
    SimpleStorage simplestorage;
function setUp() public {
        simplestorage = new SimpleStorage();
    }
function testGetInitialValue() public {
        assertTrue(simplestorage.get() == 0);
    }
function testSetValue() public {
        uint x = 300;
        simplestorage.set(x);
        assertTrue(simplestorage.get() == 300);
    }
}
