// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../FraudProof.sol";

import "../libraries/UTXO.sol";
import "../libraries/MerkleProof.sol";

import "./utils/BuildMerkleRoot.sol";
import "./utils/Cast.sol";

contract BaseTest is DSTest {
    using Cast for uint256;
    using Cast for bytes32;

    Vm vm = Vm(HEVM_ADDRESS);
    FraudProof fraudProof;

    function setUp() public {
        fraudProof = new FraudProof();
    }

    function testDeployment() public {
        assertTrue(address(fraudProof) != address(0));
    }

    function testCannotContestOrigin(address prover, bytes32 randomRoot) public {
        fraudProof.updateRoot(randomRoot);
        vm.prank(prover);
        vm.expectRevert(FraudProof.CannotContestOrigin.selector);

        bytes32[] memory indices = new bytes32[](1);
        Transaction memory trx;
        Transaction[] memory inputs = new Transaction[](1);
        fraudProof.proveFraud(0, 0, indices, trx, inputs);
    }

    function testInvalidCheckpoint(address prover, uint256 checkpoint, bytes32 randomRoot) public {
        fraudProof.updateRoot(randomRoot);

        vm.assume(checkpoint > fraudProof._currentRootIndex());
        vm.prank(prover);
        vm.expectRevert(FraudProof.InvalidCheckpoint.selector);

        bytes32[] memory indices = new bytes32[](1);
        Transaction memory trx;
        Transaction[] memory inputs = new Transaction[](1);
        fraudProof.proveFraud(checkpoint, 0, indices, trx, inputs);
    }

    // function testInvalidMerkleProof() public view {
    //     // Transaction memory transaction1;
    //     // Transaction memory transaction2;

    //     // {
    //     //     Vin[] memory vin = new Vin[](0);
    //     //     Vout[] memory vout = new Vout[](2);
    //     //     vout[0] = Vout(address(0xDEAD), 100);
    //     //     vout[1] = Vout(address(0xBEEF), 200);
    //     //     transaction1 = Transaction(vin, vout);
    //     // }

    //     // {
    //     //     Vin[] memory vin = new Vin[](0);
    //     //     Vout[] memory vout = new Vout[](2);
    //     //     vout[0] = Vout(address(0xDEAD), 300);
    //     //     vout[1] = Vout(address(0xBEEF), 400);
    //     //     transaction2 = Transaction(vin, vout);
    //     // }

    //     // bool[] memory spent = new bool[](2);

    //     // bytes32 leaf = keccak256(abi.encode(transaction1, spent));
    //     // bytes32 leaf2 = keccak256(abi.encode(transaction2, spent));

    //     // bytes32[] memory leaves = new bytes32[](2);
    //     // leaves[0] = leaf;
    //     // leaves[1] = leaf2;

    //     // bytes32[] memory leaves = new bytes32[](3);
    //     // // bytes32[] memory hashes = BuildMerkleRoot.buildSubtree(1, leaves);
    //     // bytes32[] memory res = BuildMerkleRoot.buildSubtree(bytes32(uint256(4)), 4, leaves);

    //     // bytes32 h1 = keccak256(abi.encode(bytes32(uint256(4)), 0));
    //     // console.logBytes32(res[0]);
    //     // console.logBytes32(h1);
    //     // console.log("======");

    //     // bytes32 h2 = keccak256(abi.encode(h1, 0));
    //     // console.logBytes32(res[1]);
    //     // console.logBytes32(h2);
    //     // console.log("======");

    //     // bytes32 h3 = keccak256(abi.encode(0, h2));
    //     // console.logBytes32(res[2]);
    //     // console.logBytes32(h3);
    //     // console.log("======");

    //     // bytes32[160] memory hashes = BuildMerkleRoot.emptySparseMerkleTree160();

    //     // for (uint256 i = 0; i < 160; i++) {
    //     //     console.logBytes32(hashes[i]);
    //     // }

    //     bytes32[] memory empty = new bytes32[](4);
    //     bytes32[] memory initialProofs = new bytes32[](0);

    //     // {
    //     //     (bytes32 root,,) = BuildMerkleRoot.buildCompressedProof(empty, initialProofs, 0, bytes32(0));
    //     //     console.logBytes32(root);
    //     // }

    //     // console.log("============");
    //     // empty[0] = Cast.toBytes32(1);

    //     // {
    //     //     (bytes32 root,, bytes32 bitmap) = BuildMerkleRoot.buildCompressedProof(empty, initialProofs, 0, bytes32(0));
    //     //     console.logBytes32(root);

    //     //     bytes32 h1 = keccak256(abi.encode(empty[0], 0));
    //     //     bytes32 test = keccak256(abi.encode(h1, 0));

    //     //     console.logBytes32(test);
    //     //     console.logBytes32(bitmap);

    //     //     empty[0] = bytes32(0);
    //     // }

    //     // console.log("============");
    //     // empty[1] = Cast.toBytes32(2);

    //     // {
    //     //     (bytes32 root,, bytes32 bitmap) = BuildMerkleRoot.buildCompressedProof(empty, initialProofs, 0, bytes32(0));
    //     //     console.logBytes32(root);

    //     //     bytes32 h1 = keccak256(abi.encode(empty[0], empty[1]));
    //     //     bytes32 test = keccak256(abi.encode(h1, 0));

    //     //     console.logBytes32(test);
    //     //     console.logBytes32(bitmap);
    //     // }

    //     console.log("============");
    //     empty[0] = Cast.toBytes32(1);
    //     empty[1] = Cast.toBytes32(2);

    //     {
    //         (bytes32 root, bytes32[] memory wtf, bytes32 bitmap) =
    //             BuildMerkleRoot.buildCompressedProof(empty, initialProofs, 0, bytes32(0));
    //         console.logBytes32(root);

    //         bytes32 h1 = keccak256(abi.encode(empty[0], empty[1]));
    //         bytes32 test = keccak256(abi.encode(h1, 0));

    //         console.logBytes32(test);
    //         console.log(bitmap.getBitAt(0));
    //         console.log(wtf.length);
    //     }
    // }
}
