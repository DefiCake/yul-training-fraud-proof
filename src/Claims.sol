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

    mapping(bytes32 => ClaimTree) private trees;

    function commitRoot(bytes calldata data) external returns (bytes32 _hash) {
        ClaimTree memory tree = ClaimTree(0, block.timestamp, 0, data);
        _hash = keccak256(abi.encode(tree));
        trees[_hash] = tree;
    }

    function challenge(bytes32 parentHash, bytes calldata data) external returns (bytes32 _hash) {
        require(trees[parentHash].timestamp > 0);

        ClaimTree memory parentTree = trees[parentHash];
        ClaimTree memory grandparentTree = trees[parentTree.parent];
        uint256 consumedTime = block.timestamp - parentTree.timestamp + grandparentTree.opponentConsumedTime;

        require(consumedTime < clock, "Timeout");
        ClaimTree memory tree = ClaimTree(parentHash, block.timestamp, consumedTime, data);

        _hash = keccak256(abi.encode(tree));
        trees[_hash] = tree;
    }

    function getTree(bytes32 _hash) public view returns (ClaimTree memory ret) {
        ret = trees[_hash];
    }
}
