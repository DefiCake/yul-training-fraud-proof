// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "./utils/rehash.sol";
import "./harness/ClaimChessClocks.harness.sol";

contract ClaimChessClocksTest is DSTest, Test {
    using Rehash for bytes;
    using Rehash for bytes32;

    uint256 private constant clock = 300 seconds;

    ClaimChessClocksHarness harness;

    function setUp() public {
        vm.warp(1641070800); // Sets initial timestamp;
        harness = new ClaimChessClocksHarness(clock);
    }

    function test_startClock(bytes32 id) external {
        vm.assume(id != 0);
        harness.startClock(id);
        ClaimChessClocks.Clock memory newClock = harness.getClock(id);
        assertEq(newClock.parent, 0);
        assertEq(newClock.timestamp, block.timestamp);
        assertEq(newClock.consumedTime, 0);
    }

    function test_startClockIdCannotBe0() external {
        vm.expectRevert("ID_NOT_ZERO");
        harness.startClock(0);
    }

    function test_passTurn_singleTurn(uint48 time, bytes32 parent, bytes32 id) external {
        vm.assume(time < clock);
        vm.assume(parent != 0);
        vm.assume(id != 0);
        vm.assume(parent != id);

        harness.startClock(parent);
        skip(time);
        harness.passTurn(id, parent);

        ClaimChessClocks.Clock memory newClock = harness.getClock(id);

        assertEq(newClock.parent, parent);
        assertEq(newClock.timestamp, block.timestamp);
        assertEq(newClock.consumedTime, time);
    }

    function test_passTurn_severalTurns(uint8 turns, bytes32 parent, bytes32 id) external {
        vm.assume(parent != 0);
        vm.assume(id != 0);
        vm.assume(parent != id);

        harness.startClock(parent);

        for (uint256 i = 0; i < turns; i++) {
            skip(1);
            harness.passTurn(id, parent);
            ClaimChessClocks.Clock memory attackerClock = harness.getClock(id);

            assertEq(attackerClock.parent, parent);
            assertEq(attackerClock.timestamp, block.timestamp);
            assertEq(attackerClock.consumedTime, i + 1);

            parent = id;
            id = id.rehash(1);

            skip(1);
            harness.passTurn(id, parent);
            ClaimChessClocks.Clock memory defenderClock = harness.getClock(id);

            assertEq(defenderClock.parent, parent);
            assertEq(defenderClock.timestamp, block.timestamp);
            assertEq(defenderClock.consumedTime, i + 1);

            parent = id;
            id = id.rehash(1);
        }
    }

    function test_passTurn_RevertIfExpired(uint48 time, bytes32 parent, bytes32 id) external {
        vm.assume(time > clock);
        vm.assume(parent != 0);
        vm.assume(id != 0);
        vm.assume(parent != id);

        harness.startClock(parent);
        skip(time);

        vm.expectRevert("TIMEOUT");
        harness.passTurn(id, parent);
    }

    function test_passTurn_RevertIfParentNotExists(bytes32 parent, bytes32 id) external {
        vm.assume(id != 0);
        vm.expectRevert("PARENT_NOT_EXISTS");
        harness.passTurn(id, parent);
    }

    function test_passTurn_RevertIfIdIsZero(bytes32 parent) external {
        vm.assume(parent != 0);
        harness.startClock(parent);

        vm.expectRevert("ID_NOT_ZERO");
        harness.passTurn(0, parent);
    }

    function test_passTurn_RevertIfParentIdIsZero(bytes32 parent, bytes32 id) external {
        vm.assume(parent != 0);
        vm.assume(id != 0);
        vm.assume(parent != id);
        harness.startClock(parent);

        vm.expectRevert("PARENT_NOT_ZERO");
        harness.passTurn(id, 0);
    }
}
