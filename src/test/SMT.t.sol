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

contract BaseTest is DSTest {
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

    // function testGetValue() public {
    //     // bytes32 root = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    //     // // smt.getDbValue(root);

    //     // // bytes memory value =
    //     // //     hex"11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222";

    //     // // smt.setValue(root, value);

    //     // smt.getValue(root, 0x7000000000000000000000000000000000000000000000000000000000000000);
    // }
}
