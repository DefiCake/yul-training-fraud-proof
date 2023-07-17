// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "./utils/rehash.sol";
import "../Claims.sol";

contract ClaimTreeTest is DSTest, Test {
    using Rehash for bytes;

    uint256 private constant clock = 15 seconds;

    Claims claimsTree;

    function setUp() public {
        claimsTree = new Claims(clock);
    }

    function test_CanChallengeRootClaim(address challenger1, address challenger2, uint256 time, bytes32 seed)
        external
    {
        vm.assume(time < clock);
        vm.prank(challenger1);

        bytes memory _seed = abi.encode(seed);

        bytes32 rootClaim = claimsTree.commitRoot(abi.encode(_seed.rehash(1)));
        skip(time);

        vm.prank(challenger2);
        bytes32 counterClaim = claimsTree.challenge(rootClaim, abi.encode(_seed.rehash(2)));

        assertEq(claimsTree.getTree(counterClaim).parent, rootClaim);
    }

    function test_CannotChallengeRootClaimAfterClock(
        address challenger1,
        address challenger2,
        uint48 time,
        bytes32 seed
    ) external {
        vm.assume(time > clock);
        vm.prank(challenger1);

        bytes memory _seed = abi.encode(seed);

        bytes32 rootClaim = claimsTree.commitRoot(abi.encode(_seed.rehash(1)));

        skip(time);
        {
            bytes memory rehash = abi.encode(_seed.rehash(2));
            vm.prank(challenger2);
            vm.expectRevert("Timeout");
            claimsTree.challenge(rootClaim, rehash);
        }
    }
}
