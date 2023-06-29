// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Vin {
    bytes32 txhash;
    uint256[] vout;
}

struct Vout {
    address to;
    uint256 value;
}

struct Transaction {
    Vin[] vin;
    Vout[] vout;
}
