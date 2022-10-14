// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IProject.sol";
import "../interfaces/IAudit.sol";
import '../libraries/BytesLib.sol';
import "../storages/LibDiamond.sol";
import "../storages/ProjectRegistryStorage.sol";
import "hardhat/console.sol";

contract ProjectRegistryFacet {
    using BytesLib for bytes;

    function createProject(bytes calldata _sector, bytes32 _projectId, bytes calldata _dataString) external {
        LibDiamond.enforceIsContractOwner();
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.projectContractVersions[projectRegistryStorage.projectContractVersions.length - 1];
        createProjectWithVersion(_sector, _projectId, latestContractVersion, _dataString);
    }

    function createProjectWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion, bytes calldata _dataString) public {
        LibDiamond.enforceIsContractOwner();
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes memory functionString = "createProjectContract(bytes32,bytes32,bytes)";
        bytes4 functionSelector = bytes4(keccak256(functionString));
        address facet = ds.selectorToFacetAndPosition[functionSelector].facetAddress;
        (bool success, bytes memory result) = address(facet).delegatecall(abi.encodeWithSignature(functionString.toString(), _contractVersion, _projectId, _dataString));
        require(success, 'Delegate call failed');
        address createdAddress = abi.decode(result, (address));

        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        projectRegistryStorage.projects[key] = createdAddress;
    }

    function createAudit(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId, bytes calldata _dataString) external {
        LibDiamond.enforceIsContractOwner();
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.auditContractVersions[projectRegistryStorage.auditContractVersions.length - 1];
        return createAuditWithVersion(_sector, _projectId, latestContractVersion, _auditId, _dataString);
    }

    function createAuditWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId, bytes32 _contractVersion, bytes calldata _dataString) public {
        LibDiamond.enforceIsContractOwner();
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);
        
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes memory functionString = "createAuditContract(bytes32,bytes32,bytes32,bytes)";
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        address facet = ds.selectorToFacetAndPosition[bytes4(keccak256(functionString))].facetAddress;
        (bool success, bytes memory result) = address(facet).delegatecall(abi.encodeWithSignature(functionString.toString(), _contractVersion, _projectId, _auditId, _dataString));
        require(success, 'Delegate call failed');
        address createdAddress = abi.decode(result, (address));

        projectRegistryStorage.audits[key][_auditId] = createdAddress;
        projectRegistryStorage.auditAddresses[key].push(createdAddress);
    }

    // function getProjectDataByFunctionSelector(bytes calldata _sector, bytes32 _projectId, string calldata _functionSig, bytes calldata _data) external returns(bytes memory) {
    //     ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
    //     bytes32 latestContractVersion = projectRegistryStorage.projectContractVersions[projectRegistryStorage.projectContractVersions.length - 1];

    //     return getProjectDataByFunctionSelectorWithVersion(_sector, _projectId, latestContractVersion, _functionSig, _data);
    // }

    // function getProjectDataByFunctionSelectorWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion, string calldata _functionSig, bytes calldata _data) public returns(bytes memory) {
    //     bytes memory keyString = "";
    //     keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
    //     bytes32 key = keccak256(keyString);
        
    //     ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
    //     (bool success, bytes memory result) = address(projectRegistryStorage.projects[key]).delegatecall(abi.encodeWithSignature(_functionSig, _data));
    //     require(success, 'Delegate call failed');
    //     return result;
    // }

    function getProjectData(bytes calldata _sector, bytes32 _projectId) external view returns(bytes memory) {
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.projectContractVersions[projectRegistryStorage.projectContractVersions.length - 1];

        return getProjectDataWithVersion(_sector, _projectId, latestContractVersion);
    }

    function getProjectDataWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion) public view returns(bytes memory) {
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        return IProject(projectRegistryStorage.projects[key]).getDataString();
    }

    function getAuditData(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId) external view returns(bytes memory) {
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.auditContractVersions[projectRegistryStorage.auditContractVersions.length - 1];

        return getAuditDataWithVersion(_sector, _projectId, _auditId, latestContractVersion);
    }

    function getAuditDataWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId, bytes32 _contractVersion) public view returns(bytes memory) {
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        return IAudit(projectRegistryStorage.audits[key][_auditId]).getDataString();
    }

    function updateProjectData(bytes calldata _sector, bytes32 _projectId, bytes calldata _dataString) external {
        LibDiamond.enforceIsContractOwner();
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.projectContractVersions[projectRegistryStorage.projectContractVersions.length - 1];

        updateProjectDataWithVersion(_sector, _projectId, latestContractVersion, _dataString);
    }

    function updateProjectDataWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion, bytes calldata _dataString) public {
        LibDiamond.enforceIsContractOwner();
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        IProject(projectRegistryStorage.projects[key]).updateProjectData(_projectId, _dataString);
    }

    function updateAuditData(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId, bytes calldata _dataString) public {
        LibDiamond.enforceIsContractOwner();
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.auditContractVersions[projectRegistryStorage.auditContractVersions.length - 1];

        updateAuditDataWithVersion(_sector, _projectId, _auditId, latestContractVersion, _dataString);
    }

    function updateAuditDataWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId, bytes32 _contractVersion, bytes calldata _dataString) public {
        LibDiamond.enforceIsContractOwner();
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        IAudit(projectRegistryStorage.audits[key][_auditId]).updateAuditData(_projectId, _auditId, _dataString);
    }

    function updateProjectContractVersion(bytes32 _version) external {
        LibDiamond.enforceIsContractOwner();
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        projectRegistryStorage.projectContractVersions.push(_version);
    }

    function updateAuditContractVersion(bytes32 _version) external {
        LibDiamond.enforceIsContractOwner();
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        projectRegistryStorage.auditContractVersions.push(_version);
    }

    function getProjectContractAddress(bytes calldata _sector, bytes32 _projectId) public view returns(address) {
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.projectContractVersions[projectRegistryStorage.projectContractVersions.length - 1];
        return getProjectContractAddressWithVersion(_sector, _projectId, latestContractVersion);
    }

    function getProjectContractAddressWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion) public view returns(address) {
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);

        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        return projectRegistryStorage.projects[key];
    }

    function getAuditContractAddress(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId) public view returns(address) {
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.auditContractVersions[projectRegistryStorage.auditContractVersions.length - 1];
        return getAuditContractAddressWithVersion(_sector, _projectId, _auditId, latestContractVersion);
    }

    function getAuditContractAddressWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _auditId, bytes32 _contractVersion) public view returns(address) {
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);

        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        return projectRegistryStorage.audits[key][_auditId];
    }
    function getAuditContractAddresses(bytes calldata _sector, bytes32 _projectId) public view returns(address[] memory) {
        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        bytes32 latestContractVersion = projectRegistryStorage.auditContractVersions[projectRegistryStorage.auditContractVersions.length - 1];
        return getAuditContractAddressesWithVersion(_sector, _projectId, latestContractVersion);
    }
    function getAuditContractAddressesWithVersion(bytes calldata _sector, bytes32 _projectId, bytes32 _contractVersion) public view returns(address[] memory) {
        bytes memory keyString = "";
        keyString = keyString.concat(_sector).concat(abi.encodePacked(_projectId)).concat(abi.encodePacked(_contractVersion));
        bytes32 key = keccak256(keyString);

        ProjectRegistryStorage.ProjectRegistry storage projectRegistryStorage = ProjectRegistryStorage.projectRegistryStruct();
        return projectRegistryStorage.auditAddresses[key];
    }
}