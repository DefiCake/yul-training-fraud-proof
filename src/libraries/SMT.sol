// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

contract SMT {
    uint256 private constant DEPTH = 256;

    mapping(bytes32 => bytes) private db;

    constructor() {
        bytes memory value =
            hex"11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222";
        bytes32 root = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        db[root] = value;
    }

    function setValue(bytes32 key, bytes calldata value) external {
        db[key] = value;
    }

    function getDbValue(bytes32 key) external view returns (bytes memory) {
        return db[key];
    }

    function writeValue(bytes32 root, bytes calldata value) external returns (bytes32 /*root*/ ) {
        bytes32 key = keccak256(value);
        bytes32 path = key;
        uint256 path2 = uint256(key);

        bytes32[DEPTH] memory sidenodes;

        for (uint256 i = 0; i < DEPTH;) {
            bytes32 slot;
            bytes32 sidenode;

            assembly {
                mstore(0x00, root)
                mstore(0x20, 0x00)
                mstore(0x00, keccak256(0x00, 0x40))
                slot := keccak256(0x00, 0x20)

                // If the path is to the left, load right slot
                if eq(shr(255, path), 0) { slot := add(slot, 1) }

                sidenode := sload(slot)
            }

            sidenodes[i] = sidenode;
            path = path << 1;

            unchecked {
                ++i;
            }
        }

        db[key] = value;

        for (uint256 i = 0; i < DEPTH;) {
            bytes memory nodeValue = path2 % 2 == 0
                ? abi.encodePacked(key, sidenodes[DEPTH - i - 1])
                : abi.encodePacked(sidenodes[DEPTH - i - 1], key);

            key = keccak256(nodeValue);
            db[key] = nodeValue;

            path2 = path2 >> 1;

            unchecked {
                ++i;
            }
        }

        return key;
    }

    function getValue(bytes32 root, bytes32 key) external view returns (bytes memory value) {
        bytes32 slot;
        bytes32 path = key;

        for (uint256 i = 0; i < DEPTH;) {
            assembly {
                mstore(0x00, root)
                mstore(0x20, 0x00)
                mstore(0x00, keccak256(0x00, 0x40))
                slot := keccak256(0x00, 0x20)

                // If the path is to the right, load the contiguous (rightmost) slot
                if eq(and(shr(255, path), 1), 1) { slot := add(slot, 1) }

                root := sload(slot)
            }

            if (root == bytes32(0)) return db[bytes32(0)];

            path = path << 1;
            unchecked {
                ++i;
            }
        }

        return db[root];
    }

    function hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (uint256(a) == 0 && uint256(b) == 0) return 0;

        return keccak256(abi.encode(a, b));
    }

    function getRoot(bytes32[] calldata leaves) external returns (bytes32) {
        for (uint256 i = 0; i < leaves.length; ++i) {}
    }
}
