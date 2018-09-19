pragma solidity ^0.4.24;

import "./Utils.sol";
import "./CompensationChamber.sol";
import "./Derivative.sol";

contract PaymentRequest
{
  uint private value;
  Utils.paymentType private payType;
  bool private payed;

  address owner;
  address clearingMemberAddress;
  address compensationChamberAddress;

  constructor (uint _value, address _clearingMemberAddress, address _compensationChamberAddress, Utils.paymentType _payType)
  {
    owner = msg.sender;
    compensationChamberAddress = _compensationChamberAddress;
    clearingMemberAddress = _clearingMemberAddress;
    value = _value;
    payType = _payType;
    payed = false;

    CompensationChamber _compensationChamberContract = CompensationChamber(compensationChamberAddress);
    _compensationChamberContract.paymentRequest(value, clearingMemberAddress);
  }
  function getValue() view public returns(uint)
  {
      return value;
  }

  function getClearingMember() view public returns(address)
  {
      return clearingMemberAddress;
  }

  function getOwner() view public returns(address)
  {
      return owner;
  }

  function pay() public payable returns (bool)
  {
      require(msg.value >= value);
      payed = true;

      if (payType == Utils.paymentType.initialMargin)
      {
        Derivative _derivative = Derivative(owner);
        _derivative.initialMarginPayment.value(msg.value)(clearingMemberAddress);
      }
      else if (payType == Utils.paymentType.variationMargin)
      {
        compensationChamberAddress.send(msg.value);
      }
      return payed;
  }

  function isPayed() view public returns(bool)
  {
      return payed;
  }
}
