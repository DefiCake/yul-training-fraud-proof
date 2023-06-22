// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";

library BuildMerkleRoot {
    function buildRoot(bytes32[] memory leaves) public view returns (bytes32) {
        require(leaves.length > 0, "Length of leaves must be > 0");
        if (leaves.length == 1) return leaves[0];

        uint256 nextLevelLength = leaves.length % 2 == 0 ? leaves.length / 2 : leaves.length / 2 + 1;
        bytes32[] memory nextLevel = new bytes32[](nextLevelLength);

        for (uint256 i = 0; i < leaves.length / 2; i++) {
            nextLevel[i] = keccak256(abi.encode(leaves[2 * i], leaves[(2 * i) + 1]));
        }

        if (leaves.length % 2 == 1) {
            nextLevel[nextLevelLength - 1] = keccak256(abi.encode(leaves[leaves.length - 1], leaves[leaves.length - 1]));
        }

        return buildRoot(nextLevel);
    }
}
