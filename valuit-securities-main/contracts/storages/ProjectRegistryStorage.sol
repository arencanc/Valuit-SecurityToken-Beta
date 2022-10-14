// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library ProjectRegistryStorage {

    struct ProjectRegistry {
        mapping(bytes32 => address) projects;
        mapping(bytes32 => mapping(bytes32 => address)) audits;
        mapping(bytes32 => address[]) auditAddresses;
        bytes32[] projectContractVersions;
        bytes32[] auditContractVersions;
    }

    // Returns the struct from a specified position in contract storage
    // ds is short for DiamondStorage
    function projectRegistryStruct() internal pure returns(ProjectRegistry storage ds) {
        // Specifies a random position from a hash of a string
        bytes32 storagePosition = keccak256("valuit.project.registry.storage");
        // Set the position of our struct in contract storage
        assembly {
            ds.slot := storagePosition
        }
    }
}