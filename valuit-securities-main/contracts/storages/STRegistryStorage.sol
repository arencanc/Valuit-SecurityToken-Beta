// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library STRegistryStorage {

    struct STRegistry {
        mapping(bytes32 => address) stTokens;
        //Version of ST Token storage contract or Proxy contract
        bytes32[] stTokenStorageContractVersion;
        //mapping of storage proxy contract version (e.g. V1) with address of different logic contract versions. Logic contract version Referenced by index of array.
        mapping(bytes32 => address[]) logicContractVersion;
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function stRegistryStruct() internal pure returns(STRegistry storage ds) {
        bytes32 storagePosition = keccak256("valuit.security.token.registry.storage");
        assembly {
            ds.slot := storagePosition
        }
    }
}