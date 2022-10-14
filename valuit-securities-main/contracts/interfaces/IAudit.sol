// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAudit {
  function updateAuditData(bytes32 _projectId, bytes32 _auditId, bytes memory _dataString) external;
  function getDataString() external view returns(bytes memory _dataString);
}