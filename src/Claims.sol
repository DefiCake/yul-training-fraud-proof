// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Claims {
    struct ClaimTree {
        bytes32 parent;
        uint256 timestamp;
        uint256 opponentConsumedTime;
        bytes data;
    }

    uint256 public immutable clock;

    constructor(uint256 _clock) {
        clock = _clock;
    }

    mapping(bytes32 => ClaimTree) public trees;

    function commitRoot(bytes calldata data) external returns (bytes32 hash) {
        ClaimTree memory tree = ClaimTree(0, block.timestamp, 0, data);
        hash = keccak256(abi.encode(tree));
        trees[hash] = tree;
    }

    function challenge(bytes32 parentHash, bytes calldata data) external returns (bytes32 hash) {
        require(trees[parentHash].timestamp > 0);

        ClaimTree memory parentTree = trees[parentHash];
        ClaimTree memory grandparentTree = trees[parentTree.parent];
        uint256 consumedTime = block.timestamp - parentTree.timestamp + grandparentTree.opponentConsumedTime;

        ClaimTree memory tree = ClaimTree(parentHash, block.timestamp, consumedTime, data);

        hash = keccak256(abi.encode(tree));
        trees[hash] = tree;
    }

    function getTree(bytes32 hash) public view returns (ClaimTree memory) {
        return trees[hash];
    }
}
