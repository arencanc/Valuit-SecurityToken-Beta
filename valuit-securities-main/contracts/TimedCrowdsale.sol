// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

contract TimedCrowdsale {

  uint public openingTime;
  uint public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint _openingTime, uint _closingTime) {
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open for buyers to buy token.
   * @return Whether crowdsale is active
   */
  function isSaleWindowActive() public view returns (bool) {
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }
  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }

}