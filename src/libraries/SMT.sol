// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SMT {
    uint256 private constant DEPTH = 256;

    mapping(bytes32 => bytes) private db;

    function setValue(bytes32 root, bytes32 key, bytes calldata value) external returns (bytes32 /*root*/ ) {
        uint256 path = uint256(key);

        bytes32[DEPTH] memory sidenodes = getProof(root, key);

        db[key] = value;

        for (uint256 i = 0; i < DEPTH;) {
            unchecked {
                bytes memory nodeValue =
                    path % 2 == 0 ? abi.encodePacked(key, sidenodes[i]) : abi.encodePacked(sidenodes[i], key);

                key = keccak256(nodeValue);
                db[key] = nodeValue;

                path = path >> 1;

                ++i;
            }
        }

        return key;
    }

    function getDbValue(bytes32 key) external view returns (bytes memory) {
        return db[key];
    }

    function writeValue(bytes32 root, bytes calldata value) external returns (bytes32 /*root*/ ) {
        bytes32 key = keccak256(value);
        uint256 path = uint256(key);

        bytes32[DEPTH] memory sidenodes = getProof(root, key);

        db[key] = value;

        for (uint256 i = 0; i < DEPTH;) {
            unchecked {
                bytes memory nodeValue =
                    path % 2 == 0 ? abi.encodePacked(key, sidenodes[i]) : abi.encodePacked(sidenodes[i], key);

                key = keccak256(nodeValue);
                db[key] = nodeValue;

                path = path >> 1;

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

            if (root == 0) return db[0];

            path = path << 1;
            unchecked {
                ++i;
            }
        }

        return db[root];
    }

    function getProof(bytes32 root, bytes32 path) public view returns (bytes32[DEPTH] memory sidenodes) {
        for (uint256 i = DEPTH; i > 0;) {
            unchecked {
                --i;
            }

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
        }
    }

    // Solidity impl gas: | getCompressedProof                 | 94149           | 94441    | 94588    | 94588    | 12      |
    // Assembly impl gas: | getCompressedProof                 | 26934           | 26974    | 26994    | 26994    | 12      |
    function getCompressedProof(bytes32[DEPTH] calldata /*proofs*/ ) external pure returns (bytes32[] memory cProofs) {
        assembly {
            let count := 1
            let bitmap := 0x00
            for { let i := 0 } lt(i, DEPTH) {} {
                bitmap := shr(1, bitmap)
                let proof := calldataload(add(0x04, mul(i, 0x20)))
                if gt(proof, 0x00) {
                    count := add(count, 1)
                    mstore(add(cProofs, mul(0x20, count)), proof)
                    bitmap := or(bitmap, 0x8000000000000000000000000000000000000000000000000000000000000000) // Push 1 bit on the left
                }
                i := add(i, 1)
            }

            let cProofsReturnDataPointer := sub(cProofs, 0x20)
            mstore(cProofsReturnDataPointer, 0x20)
            mstore(cProofs, count)
            mstore(add(cProofs, 0x20), bitmap)

            return(cProofsReturnDataPointer, add(0x40, mul(0x20, count)))
        }
    }

    function verifyProof(bytes32 root, bytes32 key, bytes32[DEPTH] memory proof) public pure returns (bool) {
        bytes32 currentNode = key;

        for (uint256 i = 0; i < DEPTH;) {
            currentNode = uint256(key) % 2 == 0 ? hashPair(currentNode, proof[i]) : hashPair(proof[i], currentNode);

            key = key >> 1;

            unchecked {
                ++i;
            }
        }

        return currentNode == root;
    }

    function verifyCompressedProof(bytes32 root, bytes32 key, bytes32[] memory cProofs) public pure returns (bool) {
        bytes32 bitmap = cProofs[0];
        uint256 count = 1;
        uint256 maxCount = cProofs.length;
        bytes32 currentNode = key;
        uint256 i = 0;
        for (; count < maxCount;) {
            bytes32 sidenode;

            if (uint256(bitmap >> i) % 2 == 1) {
                sidenode = cProofs[count];
                unchecked {
                    ++count;
                }
            }

            currentNode = uint256(key) % 2 == 0 ? hashPair(currentNode, sidenode) : hashPair(sidenode, currentNode);

            key = key >> 1;

            unchecked {
                ++i;
            }
        }

        for (; i < DEPTH;) {
            currentNode = uint256(key) % 2 == 0 ? hashPair(currentNode, 0) : hashPair(0, currentNode);

            key = key >> 1;

            unchecked {
                ++i;
            }
        }

        return root == currentNode;
    }

    /**
     * @dev I don't think this could benefit from yul
     */
    function verifyNonInclusionProof(bytes32 root, bytes32 nonKey, bytes32 inKey, bytes32[DEPTH] memory proof)
        public
        pure
        returns (bool)
    {
        if (root == 0) return true;

        require(nonKey > 0);
        require(inKey > 0);

        bool foundNonInclusion;
        bytes32 currentNode = inKey;
        uint256 i = 0;

        while (i < DEPTH) {
            bytes32 sidenode = proof[i];
            currentNode = uint256(inKey) % 2 == 0 ? hashPair(currentNode, sidenode) : hashPair(sidenode, currentNode);

            inKey = inKey >> 1;
            nonKey = nonKey >> 1;

            unchecked {
                ++i;
            }

            // When this happens, we break out of the loop and continue
            // without the constant checkings. At this point we know
            // the nonKey was not included in the root,
            // but we need to check that the proof is valid
            if (inKey == nonKey) {
                if (sidenode == 0) {
                    foundNonInclusion = true;
                    break;
                }

                return false;
            }
        }

        while (i < DEPTH) {
            currentNode = uint256(inKey) % 2 == 0 ? hashPair(currentNode, proof[i]) : hashPair(proof[i], currentNode);

            inKey = inKey >> 1;
            nonKey = nonKey >> 1;

            unchecked {
                ++i;
            }
        }

        return currentNode == root && foundNonInclusion;
    }

    function verifyNonInclusionCompressedProof(bytes32 root, bytes32 nonKey, bytes32 inKey, bytes32[] memory cProofs)
        public
        pure
        returns (bool)
    {
        if (root == 0) return true;

        require(nonKey > 0);
        require(inKey > 0);

        bytes32 bitmap = cProofs[0];
        bytes32 currentNode = inKey;
        uint256 i;
        uint256 count = 1;
        uint256 maxCount = cProofs.length;
        bool foundNonInclusion;

        while (count < maxCount) {
            bytes32 sidenode;

            if (uint256(bitmap >> i) % 2 == 1) {
                sidenode = cProofs[count];

                unchecked {
                    ++count;
                }
            }

            currentNode = uint256(inKey) % 2 == 0 ? hashPair(currentNode, sidenode) : hashPair(sidenode, currentNode);

            inKey = inKey >> 1;
            nonKey = nonKey >> 1;

            unchecked {
                ++i;
            }

            if (inKey == nonKey) {
                if (sidenode == 0) {
                    foundNonInclusion = true;
                    break;
                }

                return false;
            }
        }

        while (count < maxCount) {
            bytes32 sidenode;

            if (uint256(bitmap >> i) % 2 == 1) {
                sidenode = cProofs[count];

                unchecked {
                    ++count;
                }
            }

            currentNode = uint256(inKey) % 2 == 0 ? hashPair(currentNode, sidenode) : hashPair(sidenode, currentNode);

            inKey = inKey >> 1;
            nonKey = nonKey >> 1;

            unchecked {
                ++i;
            }
        }

        while (i < DEPTH) {
            currentNode = uint256(inKey) % 2 == 0 ? hashPair(currentNode, 0) : hashPair(0, currentNode);

            inKey = inKey >> 1;

            unchecked {
                ++i;
            }
        }

        return root == currentNode && foundNonInclusion;
    }

    function hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (uint256(a) == 0 && uint256(b) == 0) return 0;

        return keccak256(abi.encodePacked(a, b));
    }
}
