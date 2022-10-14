// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC1594.sol";
import "./IERC1410.sol";
import "./IERC1643.sol";
import "./IERC1644.sol";

interface IERC1400 is IERC20, IERC1410, IERC1594, IERC1643, IERC1644 {
    function transferOwnership(address newOwner) external;
    function initialize(uint256 _totalSupply) external;
    function getDefaultPartitions() external view returns (bytes32[] memory);
}