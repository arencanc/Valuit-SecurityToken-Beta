// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract UpgradeabilityStorage {
  // Address of the current implementation
  address internal _implementation;

  bool internal initialized;

  address public contractOwner;

  function enforceIsContractOwner() internal view {
    require(msg.sender == contractOwner, "Must be contract owner");
  }

  function transferContractOwner(address _newOwner) external {
    enforceIsContractOwner();
    contractOwner = _newOwner;
  }
}