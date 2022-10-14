// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../projects/ProjectV1.sol";
import "../projects/AuditV1.sol";

contract ProjectFactoryFacet {

    function createProjectContract(bytes32 _contractVersion, bytes32 _projectId, bytes memory _dataString) external returns(address _contract) {
        if(_contractVersion == "V1") {
            _contract = address(new ProjectV1(_projectId, _dataString));
        }
        // else if(_contractVersion == "V2") {
        //    _contract = address(new ProjectV2(_projectId, _dataString));
        // }
        else {
            require( 1==2, 'Version not supported');
        }
    }

    function createAuditContract(bytes32 _contractVersion, bytes32 _projectId, bytes32 _auditId, bytes memory _dataString) external returns(address _contract) {
        if(_contractVersion == "V1") {
            _contract = address(new AuditV1(_projectId, _auditId, _dataString));
        }
        // else if(_contractVersion == "V2") {
        //    _contract = address(new ProjectV2(_projectId, _dataString));
        // }
        else {
            require( 1==2, 'Version not supported');
        }
    }

}