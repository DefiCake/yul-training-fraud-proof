// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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

        // provide a transaction object and its index. Compute its hash
        bytes32 leaf = keccak256(abi.encode(transaction));

        if (!MerkleProof.verify(currentCheckpointProofs, _rootHistory[checkpoint], leaf, transactionIndex)) {
            revert InvalidMerkleProof();
        }

        if (stf(transaction, inputs, _rootHistory[checkpoint - 1])) revert ValidTransition();

        // process the transaction object through the STF
        // if the transaction is proven to be invalid, revert to the previous root

        unchecked {
            _currentRootIndex = checkpoint + 1;
        }

        return true;
    }

    function stf(Transaction memory transaction, Transaction[] memory inputs, bytes32 root)
        public
        pure
        returns (bool isValidTransition)
    {
        uint256 inputsLength = inputs.length;
        require(transaction.vin.length == inputsLength);

        for (uint256 i = 0; i < inputsLength;) {
            if (HT(inputs[i]) != transaction.vin[i].txhash) revert InvalidTransactionData();

            unchecked {
                ++i;
            }
        }
        {
            uint256 totalInputValue;
            for (uint256 i = 0; i < inputsLength;) {
                uint256 utxoLength = transaction.vin[i].vout.length;

                for (uint256 j = 0; j < utxoLength;) {
                    totalInputValue += inputs[i].vout[transaction.vin[i].vout[j]].value;
                    unchecked {
                        ++j;
                    }
                }
                unchecked {
                    ++i;
                }
            }

            uint256 totalOutputValue;
            uint256 outputsLength = transaction.vout.length;

            for (uint256 i = 0; i < outputsLength;) {
                totalOutputValue += transaction.vout[i].value;
                unchecked {
                    ++i;
                }
            }

            if (totalOutputValue != totalInputValue) return false;
        }

        return true;
    }

    function HT(Transaction memory transaction) internal pure returns (bytes32) {
        return keccak256(abi.encode(transaction));
    }

    function H(bytes32 ht, bool[] memory spent) internal pure returns (bytes32) {
        return keccak256(abi.encode(ht, spent));
    }
}

//             R
//         .........
//         H1      H2
//       ......  ......
//       H1  H2  H3  H4

// H = hash(T, bool[T.vout.length]), T: {
//     vin: [
//         {
//             txhash -> string
//             vout -> index
//         }
//     ],
//     vout: [
//         {
//             to -> string
//             value -> number
//         }
//     ],

// }

// Tengo un objeto T, comprobaciones sobre R:
// - H existe y junto con los proofs lleva a R
// - Proveo un array de tuplas p[Tvin, bool[]]. H(Tvin) debe ser coincidente con T.vin.txhash. Sumo Tvin.vout[T.vin.vout]. Debe ser igual a la suma de T.vout.value
// - Para R - 1, compruebo que existe cada H(Tvin, bool[]) con proofs adjuntos
// - Para R - 1, compruebo que Tvin.vout no ha sido ya gastado.
//     - Para cada T.vin -> (index) p[index].bool[T.vin.vout] == false . Pero tengo que tener un mapeo entre p[Tvin, bool[]] <- T.vin.vout

// #######################

// T: {
//     vin: [
//         {
//             txhash -> string
//             vout[] -> index
//         }
//     ],
//     vout: [
//         {
//             to -> string
//             value -> number
//         }
//     ],
// },

// HT = hash(T)
// H = hash(HT, bool[T.vout.length])

// Tengo un objeto T, comprobaciones sobre R
// - Existe H y se adjuntan proofs que llevan R
// - Se provee un array Tvin con el mismo orden que el de T. H(Tvin) == HT == T.vin.txhash
// - Se recorren T.vin.vout, se suman TVin.vout[T.vin.vout] y se comprueba que es igual a la suma T.vout.value
// - Para R - 1, compruebo que existe H(Tvin, bool[]) con un MerkeProof, y que len(bool) == len(Tvin.vout)
// - Para R - 1, compruebo que Tvin.vout no tiene double spend en R - 1 o en R:
//     - bool[T.vin.vout] == false ; bool[T.vin.vout] = true

// Esta solución no permite gastar un UTXO en el mismo bloque en el que se recibe... ¿puedo hacer una comprobación adicional para que el STF acepte transiciones intrabloque?
