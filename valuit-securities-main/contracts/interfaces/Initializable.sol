// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface Initializable {
  /**
  * @dev Validates the caller is the versions registry.
  * THIS FUNCTION SHOULD BE OVERRIDDEN CALLING SUPER
  */
  function initialize() external;
}