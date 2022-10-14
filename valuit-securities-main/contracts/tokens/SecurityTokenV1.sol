// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC1594.sol";
import "../interfaces/IERC1410.sol";
import "../interfaces/IERC1644.sol";
import "../interfaces/IERC1643.sol";
import "../interfaces/IProject.sol";
import "../interfaces/Initializable.sol";
import "../libraries/StatusCodes.sol";
import "./SecurityTokenStorageV1.sol";
import "./MirrorToken.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract SecurityTokenV1 is IERC1594, IERC1410, IERC1644, IERC1643, SecurityTokenStorageV1, ReentrancyGuard, ERC20, Initializable {
  using SafeMath for uint256;

  event ApprovalByPartition(bytes32 indexed partition, address indexed owner, address indexed spender, uint256 value);

  constructor() {}

  function initialize() public override {
    enforceIsContractOwner();
    require(!initialized, 'Already Initialized');
    
    _mint(msg.sender, _totalSupply.mul(10**_decimals));
    _setControllers(_controllers);
    initialized = true;
  }

  /**
   * @dev Get the smallest part of the token that’s not divisible.
   * @return The smallest non-divisible part of the token.
   */
  function granularity() external view returns(uint8) {
    return _granularity;
  }
  /**
   * @dev Check if 'value' is multiple of the granularity.
   * @param value The quantity that want's to be checked.
   * @return 'true' if 'value' is a multiple of the granularity.
   */
  function _isMultiple(uint256 value) internal view returns(bool) {
    return(value.div(_granularity).mul(_granularity) == value);
  }
  /********************************* Token default partitions *************************************/
  /**
   * @dev Get default partitions to transfer from.
   * Function used for ERC20 retrocompatibility.
   * For example, a security token may return the bytes32("unrestricted").
   * @return Array of default partitions.
   */
  function getDefaultPartitions() external view returns (bytes32[] memory) {
    return _defaultPartitions;
  }
  /**
   * @dev Set default partitions to transfer from.
   * Function used for ERC20 retrocompatibility.
   * @param partitions partitions to use by default when not specified.
   */
  function setDefaultPartitions(bytes32[] calldata partitions) external {
    enforceIsContractOwner();
    _defaultPartitions = partitions;
  }
  /************************************** Token Information ***************************************/
  /**
   * @dev Get balance of a tokenholder for a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token of partition 'partition' held by 'tokenHolder' in the token contract.
   */
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external override view returns (uint256) {
    return _balanceOfByPartition[tokenHolder][partition].balance;
  }
  /**
   * @dev Get balance of a tokenholder for a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which the balance is returned.
   * @return Amount of token of partition 'partition' held by 'tokenHolder' in the token contract.
   */
  function issueTimeByPartition(bytes32 partition, address tokenHolder) external view returns (uint256) {
    return _balanceOfByPartition[tokenHolder][partition].issuedTime;
  }
  /**
   * @dev Get partitions index of a tokenholder
   * @param tokenHolder Address for which the partitions index are returned.
   * @return Array of partitions index of 'tokenHolder'.
   */
  function partitionsOf(address tokenHolder) external override view returns (bytes32[] memory) {
    return _partitionsOf[tokenHolder];
  }
  /**************************************** Token Issuance ****************************************/
  /**
   * @dev Modifier to verify if token is issuable.
   */
  modifier isIssuableToken() {
    require(_isIssuable, "Token not issueable");
    _;
  }
  /**
   * @dev Know if new tokens can be issued in the future.
   * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
   */
  function isIssuable() external override view returns (bool) {
    return _isIssuable;
  }
  /**
   * @dev Definitely renounce the possibility to issue new tokens.
   * Once set to false, '_isIssuable' can never be set to 'true' again.
   */
  function renounceIssuance() external {
    enforceIsContractOwner();
    _isIssuable = false;
  }
  /**
   * @dev Issue tokens from default partition.
   * @param tokenHolder Address for which we want to issue tokens.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, by the issuer.
   */
  function issue(address tokenHolder, uint256 value, bytes calldata data) external override isIssuableToken {
    enforceIsContractOwner();
    require(_defaultPartitions.length != 0, "Default partition not defined");

    if(data.length == 0) {
      _issueByPartition(_defaultPartitions[0], contractOwner, tokenHolder, value, data);
    } else {
      _issueByPartition(bytesToBytes32(data), contractOwner, tokenHolder, value, data);
    }
  }
  /**
   * @dev Issue tokens from a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which we want to issue tokens.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, by the issuer.
   */
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external override isIssuableToken {
    enforceIsContractOwner();
    _issueByPartition(partition, contractOwner, tokenHolder, value, data);
  }
  /**
   * @dev Perform the issuance of tokens.
   * @param operator Address which triggered the issuance.
   * @param to Token recipient.
   * @param value Number of tokens issued.
   * @param data Information attached to the issuance, and intended for the recipient (to).
   */
  function _issue(address operator, address to, uint256 value, bytes memory data) internal {
    require(_isMultiple(value), "Value not multiple of granularity");
    require(to != address(0), "Invalid Receiver");

    // _balances[to] = _balances[to].add(value);
    _transferWithData(operator, to, value);

    emit Issued(operator, to, value, data);
    emit Transfer(address(0), to, value); // ERC20 retrocompatibility
  }
  /**
   * @dev Issue tokens from a specific partition.
   * @param toPartition Name of the partition.
   * @param operator The address performing the issuance.
   * @param to Token recipient.
   * @param value Number of tokens to issue.
   * @param data Information attached to the issuance.
   */
  function _issueByPartition(bytes32 toPartition, address operator, address to, uint256 value, bytes memory data ) internal {
    //_callTokenExtension(toPartition, operator, address(0), to, value, data, "");

    _issue(operator, to, value, data);
    _addTokenToPartition(to, toPartition, value);
    _balanceOfByPartition[to][toPartition].issuedTime = block.timestamp;
    
    if(toPartition == "Gamma") {
      mirrorToken = address(new MirrorToken(_name, _symbol, _decimals));
      MirrorToken(mirrorToken).mint(to, value);
    }
    //_callRecipientExtension(toPartition, operator, address(0), to, value, data, "");

    emit IssuedByPartition(toPartition, operator, to, value, data, "");
  }
  /*************************************** Token Redemption ***************************************/
  /**
   * @dev Redeem the amount of tokens from the address 'msg.sender'.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption, by the token holder.
   */
  function redeem(uint256 value, bytes calldata data) external override {
    _redeemByDefaultPartitions(msg.sender, msg.sender, value, data);
  }
  /**
   * @dev Redeem the amount of tokens on behalf of the address from.
   * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   */
  function redeemFrom(address from, uint256 value, bytes calldata data) external override virtual {
    require(_isOperator(msg.sender, from)
      || (value <= _allowances[from][msg.sender]), "Insufficient Allowance");

    if(_allowances[from][msg.sender] >= value) {
      _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    } else {
      _allowances[from][msg.sender] = 0;
    }

    _redeemByDefaultPartitions(msg.sender, from, value, data);
  }
  /**
   * @dev Redeem tokens of a specific partition.
   * @param partition Name of the partition.
   * @param value Number of tokens redeemed.
   * @param data Information attached to the redemption, by the redeemer.
   */
  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external override {
    _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");
  }
  /**
   * @dev Redeem tokens of a specific partition.
   * @param partition Name of the partition.
   * @param tokenHolder Address for which we want to redeem tokens.
   * @param value Number of tokens redeemed
   * @param operatorData Information attached to the redemption, by the operator.
   */
  function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata operatorData) external override {
    require(_isOperatorForPartition(partition, msg.sender, tokenHolder) || value <= _allowedByPartition[partition][tokenHolder][msg.sender], "Invalid Operator");

    if(_allowedByPartition[partition][tokenHolder][msg.sender] >= value) {
      _allowedByPartition[partition][tokenHolder][msg.sender] = _allowedByPartition[partition][tokenHolder][msg.sender].sub(value);
    } else {
      _allowedByPartition[partition][tokenHolder][msg.sender] = 0;
    }

    _redeemByPartition(partition, msg.sender, tokenHolder, value, "", operatorData);
  }
  /**
   * @dev Perform the token redemption.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   */
  function _redeem(address operator, address from, uint256 value, bytes memory data) internal {
    require(_isMultiple(value), "Value not multiple of granularity");
    require(from != address(0), "Invalid Sender");
    require(_balances[from] >= value, "Insufficient Balance");

    _balances[from] = _balances[from].sub(value);
    _balances[contractOwner] = _balances[contractOwner].add(value);

    emit Redeemed(operator, from, value, data);
    emit Transfer(from, address(0), value);  // ERC20 retrocompatibility
  }
  /**
   * @dev Redeem tokens from a default partitions.
   * @param operator The address performing the redeem.
   * @param from Token holder.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   */
  function _redeemByDefaultPartitions(address operator, address from, uint256 value, bytes memory data) internal {
    require(_defaultPartitions.length != 0, "Funds Locked");

    uint256 _remainingValue = value;
    uint256 _localBalance;

    for (uint i = 0; i < _defaultPartitions.length; i++) {
      _localBalance = _balanceOfByPartition[from][_defaultPartitions[i]].balance;
      if(_remainingValue <= _localBalance) {
        _redeemByPartition(_defaultPartitions[i], operator, from, _remainingValue, data, "");
        _remainingValue = 0;
        break;
      } else {
        _redeemByPartition(_defaultPartitions[i], operator, from, _localBalance, data, "");
        _remainingValue = _remainingValue - _localBalance;
      }
    }

    require(_remainingValue == 0, "Insufficient Balance");
  }
  /**
   * @dev Redeem tokens of a specific partition.
   * @param fromPartition Name of the partition.
   * @param operator The address performing the redemption.
   * @param from Token holder whose tokens will be redeemed.
   * @param value Number of tokens to redeem.
   * @param data Information attached to the redemption.
   * @param operatorData Information attached to the redemption, by the operator (if any).
   */
  function _redeemByPartition(bytes32 fromPartition, address operator, address from, uint256 value, bytes memory data, bytes memory operatorData) internal {
    require(_balanceOfByPartition[from][fromPartition].balance >= value, "Insufficient Balance");

    // _callSenderExtension(fromPartition, operator, from, address(0), value, data, operatorData);
    // _callTokenExtension(fromPartition, operator, from, address(0), value, data, operatorData);

    _removeTokenFromPartition(from, fromPartition, value);
    _redeem(operator, from, value, data);

    emit RedeemedByPartition(fromPartition, operator, from, value, operatorData);
  }
  /******************************** Partition Token Allowances ************************************/
  /**
   * @dev Check the value of tokens that an owner allowed to a spender.
   * @param partition Name of the partition.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the value of tokens still available for the spender.
   */
  function allowanceByPartition(bytes32 partition, address owner, address spender) external view returns (uint256) {
    return _allowedByPartition[partition][owner][spender];
  }
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of 'msg.sender'.
   * @param partition Name of the partition.
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   * @return A boolean that indicates if the operation was successful.
   */
  function approveByPartition(bytes32 partition, address spender, uint256 value) external returns (bool) {
    require(spender != address(0), "Invalid Sender");
    _allowedByPartition[partition][msg.sender][spender] = value;
    emit ApprovalByPartition(partition, msg.sender, spender, value);
    return true;
  }

  /************************************* Operator Information *************************************/
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of tokenHolder.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator.
   * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
   */
  function isOperator(address operator, address tokenHolder) external view returns (bool) {
    return _isOperator(operator, tokenHolder);
  }
  /**
   * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
   * and redeem tokens on its behalf.
   * @param operator Address to set as an operator for 'msg.sender'.
   */
  function authorizeOperator(address operator) external override {
    require(operator != msg.sender, 'Operator can not be sender');
    _authorizedOperator[operator][msg.sender] = true;
    emit AuthorizedOperator(operator, msg.sender);
  }
  /**
   * @dev Remove the right of the operator address to be an operator for 'msg.sender'
   * and to transfer and redeem tokens on its behalf.
   * @param operator Address to rescind as an operator for 'msg.sender'.
   */
  function revokeOperator(address operator) external override {
    require(operator != msg.sender, 'Operator can not be sender');
    _authorizedOperator[operator][msg.sender] = false;
    emit RevokedOperator(operator, msg.sender);
  }
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder address.
   * @param operator Address which may be an operator of 'tokenHolder'.
   * @param tokenHolder Address of a token holder which may have the 'operator' address as an operator.
   * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
   */
  function _isOperator(address operator, address tokenHolder) internal view returns (bool) {
    return (operator == tokenHolder
      || _authorizedOperator[operator][tokenHolder]
      || (_isControllable && _isController[operator])
    );
  }
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder
   * address for the given partition.
   * @param partition Name of the partition.
   * @param operator Address which may be an operator of tokenHolder for the given partition.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
   * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
   */
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorForPartition(partition, operator, tokenHolder);
  }
  /**
   * @dev Set 'operator' as an operator for 'msg.sender' for a given partition.
   * @param partition Name of the partition.
   * @param operator Address to set as an operator for 'msg.sender'.
   */
  function authorizeOperatorByPartition(bytes32 partition, address operator) external override {
    require(operator != msg.sender, 'Operator can not be sender');
    _authorizedOperatorByPartition[msg.sender][partition][operator] = true;
    emit AuthorizedOperatorByPartition(partition, operator, msg.sender);
  }
  /**
   * @dev Remove the right of the operator address to be an operator on a given
   * partition for 'msg.sender' and to transfer and redeem tokens on its behalf.
   * @param partition Name of the partition.
   * @param operator Address to rescind as an operator on given partition for 'msg.sender'.
   */
  function revokeOperatorByPartition(bytes32 partition, address operator) external override {
    require(operator != msg.sender, 'Operator can not be sender');
    _authorizedOperatorByPartition[msg.sender][partition][operator] = false;
    emit RevokedOperatorByPartition(partition, operator, msg.sender);
  }
  /**
   * @dev Indicate whether the operator address is an operator of the tokenHolder
   * address for the given partition.
   * @param partition Name of the partition.
   * @param operator Address which may be an operator of tokenHolder for the given partition.
   * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
   * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
   */
   function _isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) internal view returns (bool) {
     return (_isOperator(operator, tokenHolder)
       || _authorizedOperatorByPartition[tokenHolder][partition][operator]
       || (_isControllable && _isControllerByPartition[partition][operator])
     );
   }
  /************************************ Tranfer Validity ******************************************/
  
  // function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bytes1, bytes32) {
  //     return _canTransfer(msg.sender, _to, _value, _data);
  // }
  // function _canTransfer(address _from, address _to, uint256 _value, bytes memory _data) internal view returns (bytes1, bytes32) {
  // }

  /****************************************** Transfers *******************************************/
  /**
   * @dev Transfer token for a specified address.
   * @param to The address to transfer to.
   * @param value The value to be transferred.
   * @return A boolean that indicates if the operation was successful.
   */
  function transfer(address to, uint256 value) public override returns (bool) {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, "");
    return true;
  }
  /**
   * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder.
   */
  function transferWithData(address to, uint256 value, bytes calldata data) external override {
    _transferByDefaultPartitions(msg.sender, msg.sender, to, value, data);
  }
  /**
   * @dev Transfer tokens from one address to another.
   * @param from The address which you want to transfer tokens from.
   * @param to The address which you want to transfer to.
   * @param value The amount of tokens to be transferred.
   * @return A boolean that indicates if the operation was successful.
   */
  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require( _isOperator(msg.sender, from)
      || (value <= _allowances[from][msg.sender]), "Insufficient Allowance");

    if(_allowances[from][msg.sender] >= value) {
      _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    } else {
      _allowances[from][msg.sender] = 0;
    }

    _transferByDefaultPartitions(msg.sender, from, to, value, "");
    return true;
  }
  /**
   * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
   * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder ('from').
   */
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data) external override virtual {
    require( _isOperator(msg.sender, from)
      || (value <= _allowances[from][msg.sender]), "Insufficient Allowance");

    if(_allowances[from][msg.sender] >= value) {
      _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    } else {
      _allowances[from][msg.sender] = 0;
    }

    _transferByDefaultPartitions(msg.sender, from, to, value, data);
  }
  /**
   * @dev Transfer tokens from a specific partition.
   * @param partition Name of the partition.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, by the token holder.
   * @return Destination partition.
   */
  function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data)external override returns (bytes32) {
    return _transferByPartition(partition, msg.sender, msg.sender, to, value, data, "");
  }
  /**
   * @dev Transfer tokens from a specific partition through an operator.
   * @param partition Name of the partition.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator.
   * @return Destination partition.
   */
  function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external override returns (bytes32) {
    require(_isOperatorForPartition(partition, msg.sender, from)
      || (value <= _allowedByPartition[partition][from][msg.sender]), "Insufficient Allowance");

    if(_allowedByPartition[partition][from][msg.sender] >= value) {
      _allowedByPartition[partition][from][msg.sender] = _allowedByPartition[partition][from][msg.sender].sub(value);
    } else {
      _allowedByPartition[partition][from][msg.sender] = 0;
    }

    return _transferByPartition(partition, msg.sender, from, to, value, data, operatorData);
  }
  /**
   * @dev Perform the transfer of tokens.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   */
  function _transferWithData(address from, address to, uint256 value) internal {
    require(_isMultiple(value), "Transfer Failure");
    require(to != address(0), "Invalid Receiver");
    require(_balances[from] >= value, "Insufficient Balance");
  
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value); // ERC20 retrocompatibility 
  }
  /**
   * @dev Transfer tokens from a specific partition.
   * @param fromPartition Partition of the tokens to transfer.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @param operatorData Information attached to the transfer, by the operator (if any).
   * @return Destination partition.
   */
  function _transferByPartition(bytes32 fromPartition, address operator, address from, address to, uint256 value, bytes memory data, bytes memory operatorData) internal returns (bytes32) {
    require(_balanceOfByPartition[from][fromPartition].balance >= value, "Insufficient Balance");

    bytes32 toPartition = fromPartition;

    if(operatorData.length != 0 && data.length >= 64) {
      toPartition = _getDestinationPartition(fromPartition, data);
    }

    // _callSenderExtension(fromPartition, operator, from, to, value, data, operatorData);
    // _callTokenExtension(fromPartition, operator, from, to, value, data, operatorData);
    // require(_canTransferByPartition(from, fromPartition), 'Transfer Restricted');
    _removeTokenFromPartition(from, fromPartition, value);
    _transferWithData(from, to, value);
    _addTokenToPartition(to, toPartition, value);

    // _callRecipientExtension(toPartition, operator, from, to, value, data, operatorData);

    emit TransferByPartition(fromPartition, operator, from, to, value, data, operatorData);

    if(toPartition != fromPartition) {
      emit ChangedPartition(fromPartition, toPartition, value);
    }

    return toPartition;
  }
  /**
   * @dev Transfer tokens from default partitions.
   * Function used for ERC20 retrocompatibility.
   * @param operator The address performing the transfer.
   * @param from Token holder.
   * @param to Token recipient.
   * @param value Number of tokens to transfer.
   * @param data Information attached to the transfer, and intended for the token holder ('from').
   */
  function _transferByDefaultPartitions(address operator, address from, address to, uint256 value, bytes memory data) internal {
    require(_defaultPartitions.length != 0, "Funds Locked");

    uint256 _remainingValue = value;
    uint256 _localBalance;

    for (uint i = 0; i < _defaultPartitions.length; i++) {
      _localBalance = _balanceOfByPartition[from][_defaultPartitions[i]].balance;
      if(_remainingValue <= _localBalance) {
        _transferByPartition(_defaultPartitions[i], operator, from, to, _remainingValue, data, "");
        _remainingValue = 0;
        break;
      } else if (_localBalance != 0) {
        _transferByPartition(_defaultPartitions[i], operator, from, to, _localBalance, data, "");
        _remainingValue = _remainingValue - _localBalance;
      }
    }

    require(_remainingValue == 0, "Insufficient Balance");
  }

  /**
   * @dev Retrieve the destination partition from the 'data' field.
   * By convention, a partition change is requested ONLY when 'data' starts
   * with the flag: 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
   * When the flag is detected, the destination tranche is extracted from the
   * 32 bytes following the flag.
   * @param fromPartition Partition of the tokens to transfer.
   * @param data Information attached to the transfer. [CAN CONTAIN THE DESTINATION PARTITION]
   * @return toPartition Destination partition.
   */
  function _getDestinationPartition(bytes32 fromPartition, bytes memory data) internal pure returns(bytes32 toPartition) {
    bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bytes32 flag;
    assembly {
      flag := mload(add(data, 32))
    }
    if(flag == changePartitionFlag) {
      assembly {
        toPartition := mload(add(data, 64))
      }
    } else {
      toPartition = fromPartition;
    }
  }
  /**
   * @dev Remove a token from a specific partition.
   * @param from Token holder.
   * @param partition Name of the partition.
   * @param value Number of tokens to transfer.
   */
  function _removeTokenFromPartition(address from, bytes32 partition, uint256 value) internal {
    _balanceOfByPartition[from][partition].balance = _balanceOfByPartition[from][partition].balance.sub(value);
    _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].sub(value);

    // If the total supply is zero, finds and deletes the partition.
    if(_totalSupplyByPartition[partition] == 0) {
      uint256 index1 = _indexOfTotalPartitions[partition];
      require(index1 > 0, "Transfer Failure");

      // move the last item into the index being vacated
      bytes32 lastValue = _totalPartitions[_totalPartitions.length - 1];
      _totalPartitions[index1 - 1] = lastValue; // adjust for 1-based indexing
      _indexOfTotalPartitions[lastValue] = index1;

      _totalPartitions.pop();
      _indexOfTotalPartitions[partition] = 0;
    }

    // If the balance of the TokenHolder's partition is zero, finds and deletes the partition.
    if(_balanceOfByPartition[from][partition].balance == 0) {
      uint256 index2 = _indexOfPartitionsOf[from][partition];
      require(index2 > 0, "Transfer Failure");

      // move the last item into the index being vacated
      bytes32 lastValue = _partitionsOf[from][_partitionsOf[from].length - 1];
      _partitionsOf[from][index2 - 1] = lastValue;  // adjust for 1-based indexing
      _indexOfPartitionsOf[from][lastValue] = index2;

      _partitionsOf[from].pop();
      _indexOfPartitionsOf[from][partition] = 0;
    }
  }
  /**
   * @dev Add a token to a specific partition.
   * @param to Token recipient.
   * @param partition Name of the partition.
   * @param value Number of tokens to transfer.
   */
  function _addTokenToPartition(address to, bytes32 partition, uint256 value) internal {
    if(value != 0) {
      if (_indexOfPartitionsOf[to][partition] == 0) {
        _partitionsOf[to].push(partition);
        _indexOfPartitionsOf[to][partition] = _partitionsOf[to].length;
      }
      _balanceOfByPartition[to][partition].balance = _balanceOfByPartition[to][partition].balance.add(value);

      if (_indexOfTotalPartitions[partition] == 0) {
        _totalPartitions.push(partition);
        _indexOfTotalPartitions[partition] = _totalPartitions.length;
      }
      _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].add(value);
    }
  }

  function bytesToBytes32(bytes memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }
  // function canTransfer(address _to, uint256 _value, bytes calldata _data) external view override returns (bool result, bytes32 code) {
  //   (result, code, ) = canTransferByPartition(msg.sender, _to, _defaultPartitions[0], _value, _data);
  // }
  // function canTransferByPartition(address from, address to, bytes32 partition, uint256 value, bytes calldata data) public view override returns (bool, bytes32, bytes32) {
  //   require(_balanceOfByPartition[from][partition].balance >= value, "Insufficient Balance");
  //   return (_canTransferByPartition(from, partition), bytes32(0), bytes32(0));
  // }

  // function _canTransferByPartition(address from, bytes32 partition) internal view returns (bool) {
  //   uint256 issuedTime = _balanceOfByPartition[from][partition].issuedTime;
  //   if(partition == "Gamma") {
  //     return (block.timestamp - issuedTime) >=  180; //31536000
  //   }
  //   if(partition == "Stella") {
  //     return (block.timestamp - issuedTime) >=  180;
  //   }
  //   if(partition == "Luna") {
  //     return (block.timestamp - issuedTime) >=  180;
  //   }
  //   if(partition == "Polaris") {
  //     return true;
  //   }
  //   return false;
  // }

  /**
   * @dev Access a document associated with the token.
   * @param name Short name (represented as a bytes32) associated to the document.
   * @return Requested document + document hash + document timestamp.
   */
  function getDocument(bytes32 name) external override view returns (string memory, bytes32, uint256) {
    require(bytes(_documents[name].docURI).length != 0, 'Document does not exist');
    return (
      _documents[name].docURI,
      _documents[name].docHash,
      _documents[name].timestamp
    );
  }
  function getAllDocuments() external override view returns (bytes32[] memory) {
    return _docHashes;
  }
  /**
   * @dev Associate a document with the token.
   * @param name Short name (represented as a bytes32) associated to the document.
   * @param uri Document content.
   * @param documentHash Hash of the document [optional parameter].
   */
  function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external onlyController override {
    _documents[name] = Doc({
      docURI: uri,
      docHash: documentHash,
      timestamp: block.timestamp
    });

    if (_indexOfDocHashes[documentHash] == 0) {
      _docHashes.push(documentHash);
      _indexOfDocHashes[documentHash] = _docHashes.length;
    }

    emit DocumentUpdated(name, uri, documentHash);
  }

  function removeDocument(bytes32 _name) external onlyController override {
    require(bytes(_documents[_name].docURI).length != 0, "Document doesnt exist"); // Action Blocked - Empty document

    Doc memory data = _documents[_name];

    uint256 index1 = _indexOfDocHashes[data.docHash];
    require(index1 > 0, "Invalid index"); //Indexing starts at 1, 0 is not allowed

    // move the last item into the index being vacated
    bytes32 lastValue = _docHashes[_docHashes.length - 1];
    _docHashes[index1 - 1] = lastValue; // adjust for 1-based indexing
    _indexOfDocHashes[lastValue] = index1;

    //_totalPartitions.length -= 1;
    _docHashes.pop();
    _indexOfDocHashes[data.docHash] = 0;

    delete _documents[_name];

    emit DocumentRemoved(_name, data.docURI, data.docHash);
  }
  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyController() {
    require(_isController[msg.sender] && _isControllable, 'Not Authorised');
    _;
  }
  /**
   * @dev Get the list of controllers as defined by the token contract.
   * @return List of addresses of all the controllers.
   */
  function controllers() external view returns (address[] memory) {
    return _controllers;
  }
  /**
   * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
   * Once set to false, '_isControllable' can never be set to 'true' again.
   */
  function renounceControl() external {
    enforceIsContractOwner();
    _isControllable = false;
  }

  /**
   * @dev Set list of token controllers.
   * @param operators Controller addresses.
   */
  function setControllers(address[] calldata operators) external {
    enforceIsContractOwner();
    _setControllers(operators);
  }
  /**
   * @dev Set list of token controllers.
   * @param operators Controller addresses.
   */
  function _setControllers(address[] memory operators) internal {
    for (uint i = 0; i<_controllers.length; i++){
      _isController[_controllers[i]] = false;
    }
    for (uint j = 0; j<operators.length; j++){
      _isController[operators[j]] = true;
    }
    _controllers = operators;
  }
  /**
   * @dev Get controllers for a given partition.
   * @param partition Name of the partition.
   * @return Array of controllers for partition.
   */
  function controllersByPartition(bytes32 partition) external view returns (address[] memory) {
    return _controllersByPartition[partition];
  }
  /**
   * @dev Set list of token partition controllers.
   * @param partition Name of the partition.
   * @param operators Controller addresses.
   */
   function setPartitionControllers(bytes32 partition, address[] calldata operators) external {
     enforceIsContractOwner();
     _setPartitionControllers(partition, operators);
   }
  /**
   * @dev Know if the token can be controlled by operators.
   * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
   * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
   */
  function isControllable() external override view returns (bool) {
    return _isControllable;
  }
  /**
    * @notice This function allows an authorised address to transfer tokens between any two token holders.
    * The transfer must still respect the balances of the token holders (so the transfer must be for at most
    * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
    * @dev This function can only be executed by the `controller` address.
    * @param _from Address The address which you want to send tokens from
    * @param _to Address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    * @param _data data to validate the transfer. (It is not used in this reference implementation
    * because use of `_data` parameter is implementation specific).
    * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
    * for calling this function (aka force transfer) which provides the transparency on-chain).
    */
  function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController virtual override {
    //_updateTransfer(_from, _to, _value, _data);
    _transfer(_from, _to, _value);
    emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
  }
  /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
  function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController virtual override {
    _checkAndBurn(_tokenHolder, _value, _data);
    emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
  }
  /**
   * @dev Set list of token partition controllers.
   * @param partition Name of the partition.
   * @param operators Controller addresses.
   */
   function _setPartitionControllers(bytes32 partition, address[] memory operators) internal {
     for (uint i = 0; i<_controllersByPartition[partition].length; i++){
       _isControllerByPartition[partition][_controllersByPartition[partition][i]] = false;
     }
     for (uint j = 0; j<operators.length; j++){
       _isControllerByPartition[partition][operators[j]] = true;
     }
     _controllersByPartition[partition] = operators;
   }
  function _checkAndBurn(address _from, uint256 _value, bytes memory _data) internal returns(bool verified) {
    //verified = _updateTransfer(_from, address(0), _value, _data);
    _burn(_from, _value);
    return true;
  }
  /**
    * @notice Updates internal variables when performing a transfer
    * @param _from sender of transfer
    * @param _to receiver of transfer
    * @param _value value of transfer
    * @param _data data to indicate validation
    * @return bool success
    */
  //function _updateTransfer(address _from, address _to, uint256 _value, bytes memory _data) internal virtual nonReentrant returns(bool verified);
}