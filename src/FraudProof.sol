// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./libraries/MerkleProof.sol";
import "./libraries/UTXO.sol";
import "forge-std/console.sol";

contract FraudProof {
    error NotTheOwner();
    error CannotContestOrigin();
    error InvalidCheckpoint();
    error InvalidMerkleProof();
    error InvalidTransactionData();
    error ValidTransition();

    address private _owner;
    uint256 public _currentRootIndex = 0;
    bytes32[] private _rootHistory;

    constructor() {
        _owner = msg.sender;
    }

    function updateRoot(bytes32 root) external {
        if (msg.sender != _owner) revert NotTheOwner();

        uint256 currentRootIndex = _currentRootIndex;
        if (currentRootIndex == _rootHistory.length) _rootHistory.push(root);
        else _rootHistory[currentRootIndex] = root;

        unchecked {
            _currentRootIndex = currentRootIndex + 1;
        }
    }

    function proveFraud(
        uint256 checkpoint,
        uint256 transactionIndex,
        bytes32[] calldata currentCheckpointProofs,
        Transaction calldata transaction,
        Transaction[] calldata inputs
    ) external returns (bool) {
        if (checkpoint == 0) revert CannotContestOrigin();
        if (checkpoint > _currentRootIndex) revert InvalidCheckpoint();
    }
}
