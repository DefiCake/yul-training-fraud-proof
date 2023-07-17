// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Rehash {
    function rehash(bytes memory data, uint256 times) external pure returns (bytes32) {
        bytes32 hash = keccak256(data);

        for (uint256 i = 1; i < times; i++) {
            hash = keccak256(abi.encode(hash));
        }

        return hash;
    }

    function rehash(bytes32 data, uint256 times) external pure returns (bytes32) {
        for (uint256 i = 0; i < times; i++) {
            data = keccak256(abi.encode(data));
        }
        return data;
    }
}
