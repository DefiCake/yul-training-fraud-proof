// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../libraries/SMT.sol";

import "../libraries/UTXO.sol";
import "../libraries/MerkleProof.sol";

import "./utils/BuildMerkleRoot.sol";
import "./utils/Cast.sol";

contract SMTTest is DSTest {
    using Cast for uint256;
    using Cast for bytes32;

    Vm vm = Vm(HEVM_ADDRESS);
    SMT smt;

    function setUp() public {
        smt = new SMT();
    }

    function testWriteValue_EmptyRoot(address addy, uint256 amount) external {
        Vout memory vout = Vout(addy, amount);

        bytes memory value = abi.encode(vout);
        bytes32 key = keccak256(value);
        bytes32 newroot = smt.writeValue(bytes32(0), value);

        bytes memory recoveredValue = smt.getValue(newroot, key);
        Vout memory recoveredVout = abi.decode(recoveredValue, (Vout));

        assertEq(recoveredVout.to, vout.to, "Invalid recovered vout.to");
        assertEq(recoveredVout.value, vout.value, "Invalid recovered vout.value");
    }

    function testWriteValue_MultipleValues(uint256 seed) external {
        uint256 nInputs = 16;

        address[] memory addys = new address[](nInputs);
        uint256[] memory amts = new uint[](nInputs);

        for (uint256 i = 0; i < nInputs; i++) {
            addys[i] = address(bytes20(keccak256(abi.encode(seed, i))));
            amts[i] = uint256(keccak256(abi.encode(keccak256(abi.encode(seed, i)))));
        }

        bytes32 root;
        for (uint256 i = 0; i < addys.length; i++) {
            Vout memory vout = Vout(addys[i], amts[i]);
            bytes memory value = abi.encode(vout);
            root = smt.writeValue(root, value);
        }

        for (uint256 i = 0; i < addys.length; i++) {
            Vout memory vout = Vout(addys[i], amts[i]);
            bytes memory value = abi.encode(vout);
            bytes32 key = keccak256(value);

            bytes memory recoveredValue = smt.getValue(root, key);
            Vout memory recoveredVout = abi.decode(recoveredValue, (Vout));

            assertEq(recoveredVout.to, vout.to, "Invalid recovered vout.to");
            assertEq(recoveredVout.value, vout.value, "Invalid recovered vout.value");
        }
    }

    function testWriteValue_MultipleValuesFuzzy(uint256 seed, uint256 nInputs) external {
        nInputs = nInputs % 16;
        vm.assume(nInputs > 0);

        address[] memory addys = new address[](nInputs);
        uint256[] memory amts = new uint[](nInputs);

        for (uint256 i = 0; i < nInputs; i++) {
            addys[i] = address(bytes20(keccak256(abi.encode(seed, i))));
            amts[i] = uint256(keccak256(abi.encode(keccak256(abi.encode(seed, i)))));
        }

        bytes32 root;
        for (uint256 i = 0; i < addys.length; i++) {
            Vout memory vout = Vout(addys[i], amts[i]);
            bytes memory value = abi.encode(vout);
            root = smt.writeValue(root, value);
        }

        for (uint256 i = 0; i < addys.length; i++) {
            Vout memory vout = Vout(addys[i], amts[i]);
            bytes memory value = abi.encode(vout);
            bytes32 key = keccak256(value);

            bytes memory recoveredValue = smt.getValue(root, key);
            Vout memory recoveredVout = abi.decode(recoveredValue, (Vout));

            assertEq(recoveredVout.to, vout.to, "Invalid recovered vout.to");
            assertEq(recoveredVout.value, vout.value, "Invalid recovered vout.value");
        }
    }

    function testVerifyProof(uint256 seed, uint256 nInputs, uint256 proofedValueIndex) external {
        nInputs = nInputs % 16;
        vm.assume(nInputs > 0);
        proofedValueIndex = proofedValueIndex % nInputs;

        bytes32 root;
        bytes32 key;

        {
            address[] memory addys = new address[](nInputs);
            uint256[] memory amts = new uint[](nInputs);

            for (uint256 i = 0; i < nInputs; i++) {
                addys[i] = address(bytes20(keccak256(abi.encode(seed, i))));
                amts[i] = uint256(keccak256(abi.encode(keccak256(abi.encode(seed, i)))));
            }

            for (uint256 i = 0; i < addys.length; i++) {
                Vout memory vout = Vout(addys[i], amts[i]);
                bytes memory value = abi.encode(vout);
                root = smt.writeValue(root, value);
            }

            key = keccak256(abi.encode(Vout(addys[proofedValueIndex], amts[proofedValueIndex])));
        }

        bytes32[256] memory proof = smt.getProof(root, key);

        assertTrue(smt.verifyProof(root, key, proof), "Could not verify proof");
    }

    function testVerifyCompressedProof() external {
        bytes32[] memory keys = new bytes32[](12);
        bytes32 root;

        // Fill subtree 16..23 and 24..27
        for (uint256 i = 0; i < 12; i++) {
            keys[i] = bytes32(i + 16);
            root = smt.setValue(root, keys[i], hex"01");
        }

        // Since the tree is only filled up to level ceil(log(12)) = 4 and from there it is all zeroed,
        // There are 3 proofs. We need to account for 1 more element for the bitmap
        for (uint256 i = 0; i < 8; i++) {
            bytes32[256] memory uncompressedProofs = smt.getProof(root, keys[i]);
            bytes32[] memory compressedProofs = smt.getCompressedProof(uncompressedProofs);
            assertEq(compressedProofs.length, 5);
            assertEq(compressedProofs[0], bytes32(uint256(15))); // bitmap = 00..00..1111

            assertEq(compressedProofs[1], uncompressedProofs[0]);
            assertEq(compressedProofs[2], uncompressedProofs[1]);
            assertEq(compressedProofs[3], uncompressedProofs[2]);
            assertEq(compressedProofs[4], uncompressedProofs[3]);

            for (uint256 j = 4; j < 256; j++) {
                assertEq(uncompressedProofs[j], bytes32(0));
            }

            assertTrue(smt.verifyCompressedProof(root, keys[i], compressedProofs), "Failed compressed proofs");
        }

        for (uint256 i = 8; i < 12; i++) {
            bytes32[256] memory uncompressedProofs = smt.getProof(root, keys[i]);
            bytes32[] memory compressedProofs = smt.getCompressedProof(uncompressedProofs);
            assertEq(compressedProofs.length, 4);
            assertEq(compressedProofs[0], bytes32(uint256(11))); // bitmap = 00..00..1011

            assertEq(compressedProofs[1], uncompressedProofs[0]);
            assertEq(compressedProofs[2], uncompressedProofs[1]);
            assertEq(uncompressedProofs[2], bytes32(0));
            assertEq(compressedProofs[3], uncompressedProofs[3]);

            for (uint256 j = 4; j < 256; j++) {
                assertEq(uncompressedProofs[j], bytes32(0));
            }

            assertTrue(smt.verifyCompressedProof(root, keys[i], compressedProofs), "Failed compressed proofs");
        }
    }

    function testVerifyNonInclusionProof() external {
        bytes32 root;

        // Fill 0x01, 0x05, 0x06, 0x07, 0x0d & 0x0e
        root = smt.setValue(root, bytes32(uint256(1)), hex"01");
        root = smt.setValue(root, bytes32(uint256(5)), hex"01");
        root = smt.setValue(root, bytes32(uint256(6)), hex"01");
        root = smt.setValue(root, bytes32(uint256(7)), hex"01");
        root = smt.setValue(root, bytes32(uint256(13)), hex"01");
        root = smt.setValue(root, bytes32(uint256(14)), hex"01");

        bool result;

        // Prove that 15 (0x0f) was not included - closest included element is 14 (0x0e)
        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(15), Cast.toBytes32(14), smt.getProof(root, Cast.toBytes32(14))
        );
        assertTrue(result);

        // Prove that 8-12 (0x08 - 0x0c) were not included - closest included element is 13 (0x0d)
        for (uint256 i = 8; i < 13; i++) {
            result = smt.verifyNonInclusionProof(
                root, Cast.toBytes32(i), Cast.toBytes32(13), smt.getProof(root, Cast.toBytes32(13))
            );
            assertTrue(result);
        }

        // Prove that elements 0x02 & 0x03 were not included - closest included element is 0x01
        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(2), Cast.toBytes32(1), smt.getProof(root, Cast.toBytes32(1))
        );
        assertTrue(result);

        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(3), Cast.toBytes32(1), smt.getProof(root, Cast.toBytes32(1))
        );
        assertTrue(result);

        // Prove that elements 0x04 was not included - closest included element is 0x05
        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(4), Cast.toBytes32(5), smt.getProof(root, Cast.toBytes32(5))
        );
        assertTrue(result);

        // Trying to prove non inclusion of included elements should return false
        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(5), Cast.toBytes32(4), smt.getProof(root, Cast.toBytes32(4))
        );
        assertTrue(!result);

        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(6), Cast.toBytes32(7), smt.getProof(root, Cast.toBytes32(7))
        );
        assertTrue(!result);

        // Trying to prove non inclusion with non included elements should return false
        result = smt.verifyNonInclusionProof(
            root, Cast.toBytes32(8), Cast.toBytes32(9), smt.getProof(root, Cast.toBytes32(9))
        );
        assertTrue(!result);
    }

    function testVerifyNonInclusionCompressedProof() external {
        bytes32 root;

        // Fill 0x01, 0x05, 0x06, 0x07, 0x0d & 0x0e
        root = smt.setValue(root, bytes32(uint256(1)), hex"01");
        root = smt.setValue(root, bytes32(uint256(5)), hex"01");
        root = smt.setValue(root, bytes32(uint256(6)), hex"01");
        root = smt.setValue(root, bytes32(uint256(7)), hex"01");
        root = smt.setValue(root, bytes32(uint256(13)), hex"01");
        root = smt.setValue(root, bytes32(uint256(14)), hex"01");

        bool result;

        // Prove that 15 (0x0f) was not included - closest included element is 14 (0x0e)
        result = smt.verifyNonInclusionCompressedProof(
            root, Cast.toBytes32(15), Cast.toBytes32(14), smt.getCompressedProof(smt.getProof(root, Cast.toBytes32(14)))
        );
        // TODO add more unit testing
    }

    // function testGetValue() public {
    //     // bytes32 root = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    //     // // smt.getDbValue(root);

    //     // // bytes memory value =
    //     // //     hex"11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222";

    //     // // smt.setValue(root, value);

    //     // smt.getValue(root, 0x7000000000000000000000000000000000000000000000000000000000000000);
    // }
}
