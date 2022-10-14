// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC1400.sol";
import "./TimedCrowdsale.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract SecurityCrowdsale is TimedCrowdsale, Ownable { 
  using SafeMath for uint;

  // Crowdsale Stages
  enum CrowdsaleStage { PreICO, PostICO }

  //Supported Countries
  enum Country { USA, MALTA, CANADA}

  //User types
  enum UserType {BLUE, GREEN, RED, YELLOW, PINK}

  uint public constant BELOW_5MIL = 231650257734000000000000;
  uint public constant BELOW_20MIL = 926601030938000000000000; 

  // Default to presale stage
  CrowdsaleStage public stage = CrowdsaleStage.PreICO;

  // The token being sold
  address public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint public rate;

  // Amount of wei raised
  uint public weiRaised;

  bool public isFinalized = false;

  Country public country;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);
  event Finalized();
  
  constructor(
    uint _rate, 
    address _wallet, 
    address _token,
    uint256 _totalSupply,
    Country _country,
    uint _openingTime,
    uint _closingTime
    ) TimedCrowdsale(_openingTime, _closingTime) {
    require(_rate > 0, 'Invalid Rate');
    require(_wallet != address(0), 'Invalid wallet Address');
    require(_token != address(0), 'Invalid Token Address');

    rate = _rate;
    wallet = _wallet;
    token = _token;
    country = _country;
    IERC1400(_token).initialize(_totalSupply);
  }
  /**
   * @dev Receive function
   */
  receive() external payable {
    // update state
    weiRaised = weiRaised.add(msg.value);
    _buyTokens(msg.sender, msg.value, UserType.PINK);
  }
  /**
   * @dev low level token purchase
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary, UserType _userType) public payable {
    // update state
    weiRaised = weiRaised.add(msg.value);
    _buyTokens(_beneficiary, msg.value, _userType);
  }
  /**
   * @dev low level token purchase
   * @param _beneficiary Address performing the token purchase
   */
  function _buyTokens(address _beneficiary, uint weiAmount, UserType _userType) internal {
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint tokens = _getTokenAmount(weiAmount);
    _processPurchase(_beneficiary, tokens, _userType);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds(weiAmount);
    _postValidatePurchase(_beneficiary, weiAmount);
  }
  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal virtual onlyWhileOpen {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }
  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint _weiAmount) internal virtual {
  }
  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint _tokenAmount, UserType _userType) internal virtual {
    _deliverTokens(_beneficiary, _tokenAmount, _userType);
  }
  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint _tokenAmount, UserType _userType) internal virtual {
    IERC1400(token).issue(_beneficiary, _tokenAmount, prepareIssueData(_userType));
  }
  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint _weiAmount) internal virtual {
  }
  function _updateERC20PurchasingState(address _beneficiary, address _erc20Token, uint _amount) internal virtual {
  }
  function _updateCurrencyPurchasingState(address _beneficiary, string calldata _currency, uint _amount) internal virtual {
  }
  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
    return _weiAmount.mul(rate);
  }
  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint _weiAmount) internal {
    payable(wallet).transfer(_weiAmount);
  }
  function isPreICO() public view returns (bool){
    if(stage == CrowdsaleStage.PreICO) {
      return true;
    }
    return false;
  }
  function isPostICO() public view returns (bool){
    if(stage == CrowdsaleStage.PostICO) {
      return true;
    }
    return false;
  }
  /**
  * @dev Allows admin to update the crowdsale stage
  * @param _stage Crowdsale stage
  */
  function setCrowdsaleStage(uint _stage) public onlyOwner {
    if(uint(CrowdsaleStage.PreICO) == _stage) {
      stage = CrowdsaleStage.PreICO;
    } else if (uint(CrowdsaleStage.PostICO) == _stage) {
      stage = CrowdsaleStage.PostICO;
    }
  }
  /**
  * @dev Allows admin/owner to update the crowdsale fund address
  * @param _newWallet Crowdsale new wallet address
  */
  function setFundAddress(address _newWallet) external onlyOwner {
    wallet = _newWallet;
  }
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }
  /**
   * @dev enables token transfers, called when owner calls finalize()
  */
  function finalization() internal virtual {
    require(block.timestamp >= closingTime, 'Not yet time for Finalization');
    setCrowdsaleStage(uint(CrowdsaleStage.PostICO));
    IERC1400(token).transfer(wallet, IERC1400(token).balanceOf(address(this)));
    IERC1400(token).transferOwnership(wallet);
  }
  function prepareIssueData(UserType _userType) internal view returns (bytes memory data) {
    uint tokenTotalSupply = IERC1400(token).totalSupply();
    if(country == Country.CANADA && _userType == UserType.PINK) {// Polaris
      data = hex"506F6C61726973";
    } else if(tokenTotalSupply <= BELOW_5MIL) { 
      if(country == Country.USA && _userType == UserType.BLUE) {// Gamma
        data = hex"47616D6D61";
      } else if(country == Country.MALTA && (_userType == UserType.YELLOW || _userType == UserType.PINK)) { //Luna
        data = hex"4C756E61";
      } else {
        require( 1 == 2, 'Not Supported');
      }
    } else if(tokenTotalSupply > BELOW_5MIL && tokenTotalSupply <= BELOW_20MIL) {
      if(country == Country.USA && (_userType == UserType.RED || _userType == UserType.BLUE)) {// Stella
        data = hex"5374656C6C61";
      } else {
        require( 1 == 2, 'Not Supported');
      }
    } else {
      require( 1 == 2, 'Not Supported');
    }
  }
}