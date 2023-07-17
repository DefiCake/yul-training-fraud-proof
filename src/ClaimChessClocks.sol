// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ClaimChessClocks {
    struct Clock {
        bytes32 parent;
        uint256 timestamp;
        uint256 consumedTime;
    }

    uint256 public immutable clock;

    constructor(uint256 _clock) {
        clock = _clock;
    }

    mapping(bytes32 => Clock) private clocks;

    function _startClock(bytes32 id) internal {
        require(id != 0, "ID_NOT_ZERO");
        clocks[id] = Clock(0, block.timestamp, 0);
    }

    function _passTurn(bytes32 id, bytes32 parent) internal {
        require(id != 0, "ID_NOT_ZERO");
        require(parent != 0, "PARENT_NOT_ZERO");

        Clock memory parentClock = clocks[parent];
        require(parentClock.timestamp > 0, "PARENT_NOT_EXISTS");
        Clock memory grandParentClock = clocks[parentClock.parent];
        unchecked {
            uint256 consumedTime = block.timestamp - parentClock.timestamp + grandParentClock.consumedTime;
            require(consumedTime < clock, "TIMEOUT");
            clocks[id] = Clock(parent, block.timestamp, consumedTime);
        }
    }

    function getClock(bytes32 id) public view returns (Clock memory) {
        return clocks[id];
    }
}
