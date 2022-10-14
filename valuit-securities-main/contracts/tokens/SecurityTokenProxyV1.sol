// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./SecurityTokenStorageV1.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SecurityTokenProxyV1 is SecurityTokenStorageV1, Proxy {
  using SafeMath for uint256;

  constructor(
    address _projectAddress,
    address _contractCreator,
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint8 granularity_,
    address[] memory controllers_,
    bytes32[] memory defaultPartitions
  ) {
    contractOwner = _contractCreator;
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    require(granularity_ >= 1); // Constructor Blocked - Token granularity can not be lower than 1

    _granularity = granularity_;

    _defaultPartitions = defaultPartitions;
    _isIssuable = true;
    _isControllable = true;
    _totalSupply = IProject(_projectAddress).maxSupply();
    _controllers = controllers_;
  }
  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view override returns (address) {
    return _implementation;
  }
  /**
  * @dev Upgrades the implementation to the requested version
  * @param _logicalContract representing the version name of the new implementation to be set
  */
  function upgradeTo(address _logicalContract) public override {
    enforceIsContractOwner();
    _implementation = _logicalContract;
  }
}