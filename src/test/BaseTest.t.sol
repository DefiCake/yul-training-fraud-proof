// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../FraudProof.sol";

import "../libraries/UTXO.sol";
import "../libraries/MerkleProof.sol";

import "./utils/BuildMerkleRoot.sol";

contract BaseTest is DSTest {
    Vm vm = Vm(HEVM_ADDRESS);
    FraudProof fraudProof;

    function setUp() public {
        fraudProof = new FraudProof();
    }

    function testDeployment() public {
        assertTrue(address(fraudProof) != address(0));
    }

    function testInvalidMerkleProof() public view {
        // Transaction memory transaction1;
        // Transaction memory transaction2;

        // {
        //     Vin[] memory vin = new Vin[](0);
        //     Vout[] memory vout = new Vout[](2);
        //     vout[0] = Vout(address(0xDEAD), 100);
        //     vout[1] = Vout(address(0xBEEF), 200);
        //     transaction1 = Transaction(vin, vout);
        // }

        // {
        //     Vin[] memory vin = new Vin[](0);
        //     Vout[] memory vout = new Vout[](2);
        //     vout[0] = Vout(address(0xDEAD), 300);
        //     vout[1] = Vout(address(0xBEEF), 400);
        //     transaction2 = Transaction(vin, vout);
        // }

        // bool[] memory spent = new bool[](2);

        // bytes32 leaf = keccak256(abi.encode(transaction1, spent));
        // bytes32 leaf2 = keccak256(abi.encode(transaction2, spent));
        // bytes32[] memory leaves = new bytes32[](2);
        // leaves[0] = leaf;
        // leaves[1] = leaf2;

        bytes32[] memory hashes = BuildMerkleRoot.emptySparseMerkleTree(160);

        for (uint256 i = 0; i < hashes.length; i++) {
            console.logBytes32(hashes[i]);
        }

        // bytes32[160] memory hashes = BuildMerkleRoot.emptySparseMerkleTree160();

        // for (uint256 i = 0; i < 160; i++) {
        //     console.logBytes32(hashes[i]);
        // }
    }
}
