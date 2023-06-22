// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.19;

library MerkleProof {
    function verify(bytes32[] memory proofs, bytes32 root, bytes32 leaf, uint256 index) public pure returns (bool) {
        uint256 length = proofs.length;
        bytes32 currentHash = leaf;

        for (uint256 i = 0; i < length;) {
            currentHash = index % 2 == 0
                ? currentHash = keccak256(abi.encode(proofs[i], currentHash))
                : currentHash = keccak256(abi.encode(currentHash, proofs[i]));

            unchecked {
                ++i;
                assembly {
                    index := div(index, 2)
                }
            }
        }

        if (currentHash != root) return false;

        return true;
    }
}
