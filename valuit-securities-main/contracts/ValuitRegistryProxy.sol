// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IDiamondCut.sol";
import "./storages/LibDiamond.sol";
import "./storages/ProjectRegistryStorage.sol";
import "./storages/STRegistryStorage.sol";

contract ValuitRegistryProxy {

    constructor(IDiamondCut.FacetCut[] memory _diamondCut) {
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibDiamond.setContractOwner(tx.origin);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        projectRegistryStorage.projectContractVersions.push("V1");
        projectRegistryStorage.auditContractVersions.push("V1");

        STRegistryStorage.STRegistry storage stRegistry = STRegistryStorage.stRegistryStruct();
        stRegistry.stTokenStorageContractVersion.push("V1");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}