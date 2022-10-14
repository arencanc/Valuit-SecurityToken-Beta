// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IProject.sol";
import "../UpgradeabilityStorage.sol";
import "./ERC20Storage.sol";

contract SecurityTokenStorageV1 is ERC20Storage, UpgradeabilityStorage {

  struct BalanceDetails {
    uint256 balance;
    uint256 issuedTime;
  }

  address public mirrorToken;
  uint8 internal _granularity;
  
  // Indicate whether the token can still be issued by the issuer or not anymore.
  bool internal _isIssuable;
  /************************************************************************************************/

    // Mapping from (operator, tokenHolder) to authorized status.
  mapping(address => mapping(address => bool)) internal _authorizedOperator;

  /******************************** Partition operators mappings **********************************/
  // Mapping from (partition, tokenHolder, spender) to allowed value.
  mapping(bytes32 => mapping (address => mapping (address => uint256))) internal _allowedByPartition;

  // Mapping from (tokenHolder, partition, operator) to 'approved for partition' status.
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _authorizedOperatorByPartition;
  /************************************************************************************************/

  /*********************************** Partitions  mappings ***************************************/
  // List of partitions.
  bytes32[] internal _totalPartitions;

  // Mapping from partition to their index.
  mapping (bytes32 => uint256) internal _indexOfTotalPartitions;

  // Mapping from partition to global balance of corresponding partition.
  mapping (bytes32 => uint256) internal _totalSupplyByPartition;

  // Mapping from tokenHolder to their partitions.
  mapping (address => bytes32[]) internal _partitionsOf;

  // Mapping from (tokenHolder, partition) to their index.
  mapping (address => mapping (bytes32 => uint256)) internal _indexOfPartitionsOf;

  // Mapping from (tokenHolder, partition) to balance of corresponding partition.
  mapping (address => mapping (bytes32 => BalanceDetails)) internal _balanceOfByPartition;

  // List of token default partitions (for ERC20 compatibility).
  bytes32[] internal _defaultPartitions;
  /************************************************************************************************/

  // Indicate whether the token can still be controlled by operators or not anymore.
  bool internal _isControllable;

  // Array of controllers.
  address[] internal _controllers;

  // Mapping from operator to controller status.
  mapping(address => bool) internal _isController;

  // Mapping from partition to controllers for the partition.
  mapping (bytes32 => address[]) internal _controllersByPartition;

  // Mapping from (partition, operator) to PartitionController status.
  mapping (bytes32 => mapping (address => bool)) internal _isControllerByPartition;

  struct Doc {
    string docURI;
    bytes32 docHash;
    uint256 timestamp;
  }
  // Mapping for documents.
  mapping(bytes32 => Doc) internal _documents;
  mapping(bytes32 => uint256) internal _indexOfDocHashes;
  bytes32[] internal _docHashes; 
}