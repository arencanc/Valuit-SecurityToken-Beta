// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// @title IERC1643 Document Management (part of the ERC1400 Security Token Standards)

interface IERC1643 {

    // Document Management
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function getAllDocuments() external view returns (bytes32[] memory);
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

}