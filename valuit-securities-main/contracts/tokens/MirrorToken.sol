// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MirrorToken is ERC20, Ownable {
  using SafeMath for uint;

  constructor(string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
      // _mint(msg.sender, totalSupply_.mul(10**decimals()));
  }

  function mint(address account, uint256 amount) external onlyOwner virtual {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyOwner virtual {
    _burn(account, amount);
  }
}