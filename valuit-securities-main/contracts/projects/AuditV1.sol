// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IAudit.sol";
import '../libraries/BytesLib.sol';

contract AuditV1 is IAudit {
    using BytesLib for bytes;
    
    bytes32 public id;
    bytes32 public projectId;
    bytes32 public auditorId;
    uint public auditedValuation;
    bytes public auditSummary;
    bytes public auditReportURI;
    uint8 internal ownerAcceptance;

    constructor(bytes32 _projectId, bytes32 _auditId, bytes memory _dataString) {
        projectId = _projectId;
        id = _auditId;
        parseDataString(_dataString);
    }

    function assignAuditor(bytes32 _auditorId) external {
        auditorId = _auditorId;
    }

    function setOwnerChoice(bool _choice) external {
        ownerAcceptance = _choice ? 1 : 0;
    }

    function getOwnerChoice() external view returns(bool) {
        return ownerAcceptance == 1 ? true: false;
    }

    function setAuditSummary(bytes calldata _summary) external {
        auditSummary = _summary;
    }

    function setAuditReport(bytes calldata _uri) external {
        auditReportURI = _uri;
    }

    function updateAuditData(bytes32 _projectId, bytes32 _auditId, bytes memory _dataString) external override {
        require(projectId == _projectId, 'Invalid project Id');
        require(id == _auditId, 'Invalid Audit Id');
        parseDataString(_dataString);
    }

    function getDataString() external view override returns(bytes memory _dataString) {
        _dataString = _dataString.concat(abi.encodePacked(id));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(projectId));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(auditorId));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(auditedValuation));

        _dataString = _dataString.concat(abi.encodePacked(uint16(auditSummary.length)));
        _dataString = _dataString.concat(abi.encodePacked(auditSummary));

        _dataString = _dataString.concat(abi.encodePacked(uint16(auditReportURI.length)));
        _dataString = _dataString.concat(abi.encodePacked(auditReportURI));

        _dataString = _dataString.concat(abi.encodePacked(uint16(1)));
        _dataString = _dataString.concat(abi.encodePacked(ownerAcceptance));
    }

    function parseDataString(bytes memory _dataString) internal {
        uint si = 0;
        uint segLen;
        //Extract Id
        id = _dataString.slice(si, 32).toBytes32(0);
        si += 32;

        //Extract projectId
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        projectId =_dataString.slice(si, segLen).toBytes32(0);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract auditorId
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        auditorId =_dataString.slice(si, segLen).toBytes32(0);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract auditedValuation
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        auditedValuation =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract auditSummary
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        auditSummary =_dataString.slice(si, segLen);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract auditReportURI
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        auditReportURI =_dataString.slice(si, segLen);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract auditReportURI
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        ownerAcceptance = _dataString.slice(si, segLen).toUint8();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }
    }
}