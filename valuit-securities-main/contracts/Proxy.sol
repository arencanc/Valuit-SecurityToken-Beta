// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view virtual returns (address);

  /**
  * @dev Upgrades the implementation to the requested version
  * @param _logicalContract representing the version name of the new implementation to be set
  */
  function upgradeTo(address _logicalContract) public virtual;

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback() external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      returndatacopy(ptr, 0, returndatasize())

      switch result
      case 0 { revert(ptr, returndatasize()) }
      default { return(ptr, returndatasize()) }
    }
  }
}