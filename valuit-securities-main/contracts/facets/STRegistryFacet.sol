// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/Initializable.sol";
import '../libraries/BytesLib.sol';
import "../storages/LibDiamond.sol";
import "../storages/STRegistryStorage.sol";
import "../storages/ProjectRegistryStorage.sol";
import "../Proxy.sol";
import "hardhat/console.sol";

contract STRegistryFacet {
    using BytesLib for bytes;

    function createSTToken(bytes calldata _sector, bytes32 _projectId, bytes memory _dataString) external {
        LibDiamond.enforceIsContractOwner();
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        bytes32 latestContractVersion = stRegistryStorage.stTokenStorageContractVersion[stRegistryStorage.stTokenStorageContractVersion.length - 1];
        createSTTokenWithVersion(_sector, _projectId, latestContractVersion, _dataString);
    }
    function createSTTokenWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion, bytes memory _dataString) public {
        LibDiamond.enforceIsContractOwner();
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);
        
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestProjContractVersion = projectRegistryStorage.projectContractVersions[projectRegistryStorage.projectContractVersions.length - 1];
        keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(latestProjContractVersion));
        bytes32 projectKey = keccak256(keyString);
        address projectAddress = projectRegistryStorage.projects[projectKey];

        bytes memory factoryFunctionString = "createSecurityTokenContract(bytes32,address,address,bytes)";
        address facet = LibDiamond.diamondStorage().selectorToFacetAndPosition[bytes4(keccak256(factoryFunctionString))].facetAddress;
        (bool success, bytes memory result) = address(facet).delegatecall(abi.encodeWithSignature(factoryFunctionString.toString(), _contractVersion, projectAddress, address(this), _dataString));
        require(success, 'Delegate call failed');

        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        stRegistryStorage.stTokens[key] = abi.decode(result, (address));
        initializeSTToken(key, _contractVersion);
    }
    function initializeSTToken(bytes32 key, bytes32 _contractVersion) internal {
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        address logicalContractAddress = stRegistryStorage.logicContractVersion[_contractVersion][stRegistryStorage.logicContractVersion[_contractVersion].length - 1];
        console.log("Logical address", logicalContractAddress);
        Proxy(stRegistryStorage.stTokens[key]).upgradeTo(logicalContractAddress);
        Initializable(stRegistryStorage.stTokens[key]).initialize();
    }
    function getSTTokenAddress(bytes calldata _sector, bytes32 _projectId) external view returns(address) {
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        bytes32 latestContractVersion = stRegistryStorage.stTokenStorageContractVersion[stRegistryStorage.stTokenStorageContractVersion.length - 1];
        return getSTTokenAddressWithVersion(_sector, _projectId, latestContractVersion);
    }
    function getSTTokenAddressWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion) public view returns(address) {
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);

        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        return stRegistryStorage.stTokens[key];
    }
    function upgradeSTToken(bytes calldata _sector, bytes32 _projectId, uint8 _logicalContractVersion) public {
        LibDiamond.enforceIsContractOwner();
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        bytes32 latestContractVersion = stRegistryStorage.stTokenStorageContractVersion[stRegistryStorage.stTokenStorageContractVersion.length - 1];
        upgradeSTTokenWithVersion(_sector, _projectId, latestContractVersion, _logicalContractVersion);
    }
    function upgradeSTTokenWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion, uint8 _logicalContractVersion) public {
        LibDiamond.enforceIsContractOwner();
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);

        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        address stProxyAddress = stRegistryStorage.stTokens[key];
        address logicalContractAddress = stRegistryStorage.logicContractVersion[_contractVersion][_logicalContractVersion];
        Proxy(stProxyAddress).upgradeTo(logicalContractAddress);
    }
    function updateStorageContractVersion(bytes32 _newStorageVersion, address _newLogicalAddress) external {
        LibDiamond.enforceIsContractOwner();
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        stRegistryStorage.stTokenStorageContractVersion.push(_newStorageVersion);
        stRegistryStorage.logicContractVersion[_newStorageVersion].push(_newLogicalAddress);
    }
    function getLogicalContractAddress(bytes32 _storageVersion, uint8 _logicalContractVersion) external view returns(address) {
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        return stRegistryStorage.logicContractVersion[_storageVersion][_logicalContractVersion];
    }
    function getLatestLogicalContractAddress(bytes32 _storageVersion) external view returns(address) {
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        return stRegistryStorage.logicContractVersion[_storageVersion][stRegistryStorage.logicContractVersion[_storageVersion].length - 1];
    }
    function addNewLogicalContractVersion(bytes32 _storageVersion, address _newAddress) external {
        LibDiamond.enforceIsContractOwner();
        STRegistryStorage.STRegistry storage stRegistryStorage = STRegistryStorage.stRegistryStruct();
        stRegistryStorage.logicContractVersion[_storageVersion].push(_newAddress);
    }
}