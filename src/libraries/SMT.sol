// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

contract SMT {
    uint256 private constant DEPTH = 256;

    mapping(bytes32 => bytes) private db;

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

                // If the new root is to the left (slot), the sidenode is to the right (slot+1)
                // If the new root is to the right (slot + 1), the sidenode is to the left (slot)
                switch and(shr(255, path), 1)
                case 0 {
                    // new root is to the left
                    root := sload(slot)
                    sidenode := sload(add(slot, 1))
                }
                case 1 {
                    // new root is to the right
                    sidenode := sload(slot)
                    root := sload(add(slot, 1))
                }
            }

            sidenodes[i] = sidenode;
            path = path << 1;

            unchecked {
                ++i;
            }
        }

        db[key] = value;

        uint256 topIndex = DEPTH - 1;

        for (uint256 i = 0; i < DEPTH;) {
            unchecked {
                bytes memory nodeValue = path2 % 2 == 0
                    ? abi.encodePacked(key, sidenodes[topIndex - i])
                    : abi.encodePacked(sidenodes[topIndex - i], key);

                key = keccak256(nodeValue);
                db[key] = nodeValue;

                path2 = path2 >> 1;

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

        return keccak256(abi.encodePacked(a, b));
    }
}
