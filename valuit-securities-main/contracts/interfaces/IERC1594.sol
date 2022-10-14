// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

/**
 * @title Standard Interface of ERC1594
 */
interface IERC1594 {

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    // Token Issuance
    function isIssuable() external view returns (bool);
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;
    
    // Transfer Validity
    // function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bool, bytes32);
    // function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (bytes1, bytes32);
    // function canTransferByPartition(address from, address to, bytes32 partition, uint256 value, bytes calldata data) external view returns (bool, bytes32, bytes32);    

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

}