// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract ERC20Storage {
  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) internal _allowances;

  uint256 internal _totalSupply;

  string internal _name;
  string internal _symbol;
  uint8 internal _decimals;
}