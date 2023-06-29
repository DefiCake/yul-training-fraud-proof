// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Cast {
    function toBytes32(uint256 value) public pure returns (bytes32) {
        return bytes32(value);
    }

    function getBitAt(bytes32 value, uint256 pos) public pure returns (uint256) {
        assembly {
            let bit := and(shr(pos, value), 0x01)
            mstore(0x80, bit)
            return(0x80, 0x20)
        }
    }
}
