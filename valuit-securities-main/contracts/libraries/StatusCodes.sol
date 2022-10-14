// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library StatusCodes {

    // ERC1400 status code inspired from ERC1066
    enum Status {
        TransferFailure,
        TransferSuccess,
        InsufficientBalance,
        InsufficientAllowance,
        TransfersHalted,
        FundsLocked,
        InvalidSender,
        InvalidReceiver,
        InvalidOperator
    }

    function code(Status _status) internal pure returns (bytes1) {
        return bytes1(uint8(0x50) + (uint8(_status)));
    }
}