// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ClaimTrees {
    struct ClaimTree {
        bytes32 parent;
        uint256 timestamp;
        uint256 opponentConsumedTime;
        bytes data;
    }

    uint256 public constant clock = 3 days;

    mapping(bytes32 => ClaimTree) public trees;

    function commitRoot(bytes calldata data) external {
        ClaimTree memory tree = ClaimTree(0, block.timestamp, 0, data);
        trees[keccak256(abi.encode(tree))] = tree;
    }

    function challenge(bytes32 parentHash, bytes calldata data) external {
        require(trees[parentHash].timestamp > 0);

        ClaimTree memory parentTree = trees[parentHash];
        ClaimTree memory grandparentTree = trees[parentTree.parent];
        uint256 consumedTime = block.timestamp - parentTree.timestamp + grandparentTree.opponentConsumedTime;

        ClaimTree memory tree = ClaimTree(parentHash, block.timestamp, consumedTime, data);

        trees[keccak256(abi.encode(tree))] = tree;
    }
}
