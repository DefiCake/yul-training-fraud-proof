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

    function testWriteValue() public {
        Vout memory vout = Vout(address(0xdEADDEadBEefDEADbeefdEAdBEefdEADbEefDEaD), 5);

        bytes memory value = abi.encode(vout);
        bytes32 key = keccak256(value);

        bytes32 newroot = smt.writeValue(bytes32(0), value);

        bytes memory recoveredValue = smt.getValue(newroot, key);
        Vout memory recoveredVout = abi.decode(recoveredValue, (Vout));

        assertEq(recoveredVout.to, vout.to, "Invalid recovered vout.to");
        assertEq(recoveredVout.value, vout.value, "Invalid recovered vout.value");
    }

    function testGetValue() public {
        // bytes32 root = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        // // smt.getDbValue(root);

        // // bytes memory value =
        // //     hex"11111111111111111111111111111111111111111111111111111111111111112222222222222222222222222222222222222222222222222222222222222222";

        // // smt.setValue(root, value);

        // smt.getValue(root, 0x7000000000000000000000000000000000000000000000000000000000000000);
    }
}
