// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Cast {
    function toBytes32(uint256 value) public pure returns (bytes32) {
        return bytes32(value);
    }
}
