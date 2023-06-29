// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Bytes32Array {
    function push(bytes32[] memory array, bytes32 value) public pure returns (bytes32[] memory newArray) {
        newArray = new bytes32[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            newArray[0] = array[0];
        }
        newArray[array.length] = value;
    }
}
