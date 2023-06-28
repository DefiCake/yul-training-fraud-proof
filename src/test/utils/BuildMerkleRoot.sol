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

    /// @dev builds an merkle subtree where null values are represented by 0 - for smts
    function buildSubtree(bytes32 value, uint256 key, bytes32[] memory /*proofs*/ )
        public
        pure
        returns (bytes32[] memory)
    {
        assembly {
            // Standard sha3 hash except that it returns 0 for [a=0 && b=0]
            function hashPair(a, b) -> z {
                if or(gt(a, 0x00), gt(b, 0x00)) {
                    mstore(0x00, a)
                    mstore(0x20, b)
                    z := keccak256(0x00, 0x40)
                }
            }

            let len := mload(0x80)
            let nextWordOffset := 0xa0
            let nextWord := mload(nextWordOffset)
            for { let i := 0 } lt(i, len) {} {
                switch and(key, 0x01)
                case 0 { value := hashPair(value, nextWord) }
                default { value := hashPair(nextWord, value) }

                mstore(nextWordOffset, value)
                nextWordOffset := add(nextWordOffset, 0x20)
                nextWord := mload(nextWordOffset)

                key := div(key, 2)
                i := add(i, 1)
            }

            mstore(0x60, 0x20) // Length located at 0x20
            mstore(0x80, len) // Length value = proofs length
            return(0x60, add(0x40, mul(len, 32))) // Return [0x20][len][...words]
        }
    }
}
