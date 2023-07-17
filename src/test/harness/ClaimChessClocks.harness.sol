// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../ClaimChessClocks.sol";

contract ClaimChessClocksHarness is ClaimChessClocks {
    constructor(uint256 _clock) ClaimChessClocks(_clock) {}

    function startClock(bytes32 id) public {
        _startClock(id);
    }

    function passTurn(bytes32 id, bytes32 parent) public {
        _passTurn(id, parent);
    }
}
