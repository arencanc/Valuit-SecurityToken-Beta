// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IProject {
    function updateProjectData(bytes32 _projectId, bytes memory _dataString) external;
    function getDataString() external view returns(bytes memory _dataString);
    function maxSupply() external view returns(uint);
    function tokenPrice() external view returns(uint);
    function launchDate() external view returns(uint);
    function offeringEndDate() external view returns(uint);
}