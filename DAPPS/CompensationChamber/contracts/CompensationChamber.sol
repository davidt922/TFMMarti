pragma experimental ABIEncoderV2;

import "./Market.sol";
import "./Utils.sol";
import "./MarketData.sol";
import "./Future.sol";
import "./Settlement.sol";
import "./DailyAutoExecution.sol";
import "./PaymentRequest.sol";

contract CompensationChamber
{
  address private marketAddress;
  address private marketDataAddress;
  address private settlementAddress;

  mapping (address => bool) isAClearingMember;
  mapping (bytes32 => bool) emailIsRegistred;
  mapping (bytes32 => Utils.clearingMember) mapEmailToClearingMemberStruct;
  address[] clearingMemberAddresses;

  address[] payments;
  address[] derivatives;

  int16 numberOfClearingMembers;

  /**
   * Modifiers
   */

   modifier onlyMarket
   {
     require (msg.sender == marketAddress);
     _;
   }

   constructor (uint timeStampUntilNextAutoExecution) public payable
   {
     marketAddress = msg.sender;
     marketDataAddress = (new MarketData).value(3 ether)();
     numberOfClearingMembers = 0;
     settlementAddress = new Settlement(msg.sender);
   }

   function addClearingMember (bytes32 _name, bytes32 _email, bytes32 _password) onlyMarket public returns(int16 addressID)
   {
     if (emailIsRegistred[_email] == true)
     {
       return -1;
     }
     else
     {
       numberOfClearingMembers = numberOfClearingMembers + 1;

       emailIsRegistred[_email] = true;
       Utils.clearingMember memory _clearingMemberStruct = Utils.clearingMember(_name, _email, 0x0, _password, addressID);
       mapEmailToClearingMemberStruct[_email] = _clearingMemberStruct;

       return numberOfClearingMembers + 1;
     }
   }

   function confirmClearingMemberAddress (bytes32 _email) onlyMarket public
   {
     if (isAClearingMember[tx.origin] != true)
      {
        isAClearingMember[tx.origin] = true;
        mapEmailToClearingMemberStruct[_email].clearingMemberAddress = tx.origin;
        clearingMemberAddresses.push(tx.origin);
      }
   }

   function unpayedPaymentRequest() public onlyMarket
   {
     Market _marketContract = Market(marketAddress);
     PaymentRequest _paymentRequestContract;
     for (uint i = 0; i < payments.length; i++)
     {
       _paymentRequestContract = PaymentRequest(payments[i]);

       if (_paymentRequestContract.isPayed() == false)
       {
         _marketContract.paymentRequest(payments[i], _paymentRequestContract.getValue(), _paymentRequestContract.getClearingMember());
       }
     }
   }

   function checkSignInEmailAndPassword (bytes32 _email, bytes32 _password) onlyMarket public returns (bytes32 name, address memberAddress, int8 errorCode)
   {
     if (emailIsRegistred[_email] != true)
     {
       errorCode = -1;
     }
     else if (_password == mapEmailToClearingMemberStruct[_email].password)
     {
       name = mapEmailToClearingMemberStruct[_email].name;
       memberAddress = mapEmailToClearingMemberStruct[_email].clearingMemberAddress;
       errorCode = 0;
     }
     else
     {
       errorCode = -2;
     }
   }

   function futureNovation (address _longClearingMemberAddress, address _shortClearingMemberAddress, bytes32 _instrumentID, bytes32 _amount, bytes32 _price, uint _settlementTimestamp, Utils.market _market) onlyMarket public payable
   {
      bool _longClearingMemberAddressExist = isAClearingMember[_longClearingMemberAddress];
      bool _shortClearingMemberAddressExist = isAClearingMember[_shortClearingMemberAddress];
      require(_longClearingMemberAddressExist == true && _shortClearingMemberAddressExist == true && msg.value >= 1 ether);

      derivatives.push((new Future).value(msg.value)(_longClearingMemberAddress, _shortClearingMemberAddress, _instrumentID, _amount, _price, _settlementTimestamp, marketDataAddress, _market));
   }

   function paymentRequest(uint _value, address _clearingMemberAddress) public
   {
     payments.push(msg.sender);
     Market _marketContract = Market(marketAddress);
     _marketContract.paymentRequest(msg.sender, _value, _clearingMemberAddress);
   }

    uint counter;

    mapping (address => int) mapAddressToVMValue;

    function computeVariationMargin() public
    {
      counter = derivatives.length * 2;

      for (uint i = 0; i < derivatives.length; i++)
      {
        Derivative _derivative = Derivative(derivatives[i]);
         _derivative.computeVM();
      }
    }

    function variationMargin (Utils.variationMarginChange _VMStruct, Utils.variationMarginChange _VMStruct2)
    {
      counter = counter - 2;
      mapAddressToVMValue[_VMStruct.clearingMemberAddress] = mapAddressToVMValue[_VMStruct.clearingMemberAddress] + _VMStruct.value;
      mapAddressToVMValue[_VMStruct2.clearingMemberAddress] = mapAddressToVMValue[_VMStruct2.clearingMemberAddress] + _VMStruct2.value;

      if (counter == 0)
      {
        sendPaymentRequestOrSendPayment();
        clearMapAddressToVMValue();
      }
    }

    function sendPaymentRequestOrSendPayment() private
    {
      int value;
      address clearingMemberAddress;

      for (uint i = 0; i < clearingMemberAddresses.length; i++)
      {
        clearingMemberAddress = clearingMemberAddresses[i];
        value = mapAddressToVMValue[clearingMemberAddress];

        if (value > 0)
        {
          payments.push(new PaymentRequest(uint(value), clearingMemberAddress, this, Utils.paymentType.variationMargin));
        }
        else if (value < 0)
        {
          clearingMemberAddress.transfer( uint(value/-1));
        }
      }
    }

    function clearMapAddressToVMValue() private
    {
      for (uint i = 0; i < clearingMemberAddresses.length; i++)
      {
          mapAddressToVMValue[clearingMemberAddresses[i]] = 0;
      }
    }

    function getUnpayedPaymentRequest() public onlyMarket returns (address[] memory)
    {
      PaymentRequest _paymentrequestContract;
      address[] memory paymentRequestMemory = new address[](payments.length);

      for(uint j = 0; j < payments.length; j++)
      {
        paymentRequestMemory[j] = payments[j];
      }
      return paymentRequestMemory;
    }

}
