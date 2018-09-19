pragma solidity ^0.4.24;

import "./Utils.sol";
import "./CompensationChamber.sol";
import "./PaymentRequest.sol";
import "./OrderBook.sol";
contract Market
{
  address compensationChamberAddress;
  address owner;

  mapping (bytes32 => address) mapInstrumentIdToOrderBookAddress;
  bytes32[] instrumentID;

  modifier onlyCCP()
  {
    require (msg.sender == compensationChamberAddress);
    _;
  }

  modifier onlyOwner()
  {
      require (msg.sender == owner);
      _;
  }

  constructor(uint timeStampNextVMRevision) public payable
  {
    require (msg.value >= 15 ether);
    owner = msg.sender;
    compensationChamberAddress = (new CompensationChamber).value(12 ether)(timeStampNextVMRevision);
  }

  event logAddressID(int16 addressID);
  function addClearingMember (bytes32 _name, bytes32 _email, bytes32 _password)
  {
     CompensationChamber _compensationChamber = CompensationChamber(compensationChamberAddress);
    int16 addressID = _compensationChamber.addClearingMember(_name, _email, _password);
    emit logAddressID(addressID);
  }

  function confirmClearingMemberAddress(bytes32 _email)
  {
    CompensationChamber _compensationChamber = CompensationChamber(compensationChamberAddress);
    _compensationChamber.confirmClearingMemberAddress(_email);
  }

  event logPaymentRequest(address paymentRequestAddress, uint value, address clearingMemberAddress);

  function paymentRequest(address _paymentRequestAddress, uint _value, address _clearingMemberAddress) public /*onlyCCP*/
  {
    emit logPaymentRequest(_paymentRequestAddress, _value, _clearingMemberAddress);
  }

  event isPayed(bool _isPayed);
  function payPaymentRequest(address _paymentRequestAddress) public payable returns(bool)
  {
    PaymentRequest _paymentRequestContract = PaymentRequest(_paymentRequestAddress);
    bool _isPayed = _paymentRequestContract.pay.value(msg.value)();
    emit isPayed(_isPayed);
    return _isPayed;
  }
  // _instrumentType 0 = future, 1 = swap
  function addNewDerivative (bytes32 _instrumentID, Utils.market _market, Utils.instrumentType _instrumentType, uint _settlementTimestamp) public payable
  {
    if (mapInstrumentIdToOrderBookAddress[_instrumentID] == 0)
    {
      mapInstrumentIdToOrderBookAddress[_instrumentID] = new OrderBook(_instrumentID, _market, _instrumentType, _settlementTimestamp);
      instrumentID.push(_instrumentID);
    }
  }

  function addFutureToCCP (address _longClearingMemberAddress, address _shortClearingMemberAddress, bytes32 _instrumentID, bytes32 _amount, bytes32 _price, uint _settlementTimestamp, Utils.market _market) public
  {
    CompensationChamber _compensationChamber = CompensationChamber(compensationChamberAddress);
    _compensationChamber.futureNovation.value(1 ether)(_longClearingMemberAddress, _shortClearingMemberAddress, _instrumentID, _amount, _price, _settlementTimestamp, _market);
  }

  function addOrder (bytes32 _instrumentID, uint16 _quantity, uint16 _price, Utils.side _side) public // side 0 = buy, 1 = sell
  {
    address _orderBookAddress = mapInstrumentIdToOrderBookAddress[_instrumentID];

    if (_orderBookAddress != 0)
    {
      OrderBook _orderBook = OrderBook(_orderBookAddress);

      if (_side == Utils.side.buy) // BUY
      {
        _orderBook.addBuyOrder(_quantity, _price);
      }
      else if (_side == Utils.side.sell)
      {
        _orderBook.addSellOrder(_quantity, _price);
      }
    }
  }

  function signIn(bytes32 _email, bytes32 _password) public returns (bytes32 name, address memberAddress, int8 errorCode)
  {
    CompensationChamber _compensationChamber = CompensationChamber(compensationChamberAddress);
    (name, memberAddress, errorCode) = _compensationChamber.checkSignInEmailAndPassword(_email, _password);
  }

  event logInstrumentID(bytes32 _instrumentID);

  function getInstruments() public
  {
    for (uint i = 0; i < instrumentID.length; i++)
    {
      emit logInstrumentID(instrumentID[i]);
    }
  }

  event logMarketOrder(bytes32 instrumentID, uint16 quantity, uint16 price, Utils.side side, Utils.orderType orderType); // orderType 0 = add, 1 = remove
  function OrderEvent(bytes32 _instrumentID, uint16 _quantity, uint16 _price, Utils.side _side, Utils.orderType _orderType)
  {
    emit logMarketOrder(_instrumentID, _quantity, _price, _side, _orderType);
  }
  event logMarketOrder2(bytes32 instrumentID, uint16 quantity, uint16 price, Utils.side side, Utils.orderType orderType, address txOrigin); // orderType 0 = add, 1 = remove

  event logPaymentRequestAddressAtSetup(address paymentRequestAddress);
  function getMarket() public
  {
    uint j;
    for (uint i = 0; i < instrumentID.length; i++)
    {
      address _orderBookAddress = mapInstrumentIdToOrderBookAddress[instrumentID[i]];
        OrderBook _orderBook = OrderBook(_orderBookAddress);
      uint askLength = _orderBook.getAskOrdersLength();

      uint16 _quantity;
      uint16 _price;
      for (j = 0; j < askLength; j++)
      {
        (_quantity, _price) = _orderBook.getAskOrders(j);
        emit logMarketOrder2(instrumentID[i], _quantity, _price, Utils.side.sell, Utils.orderType.add, tx.origin);
      }
      uint bidLength = _orderBook.getBidOrdersLength();
      for (j = 0; j < bidLength; j++)
      {
        (_quantity, _price) = _orderBook.getBidOrders(j);
        emit logMarketOrder2(instrumentID[i], _quantity, _price, Utils.side.buy, Utils.orderType.add, tx.origin);
      }
    }
    CompensationChamber _compensationChamberContract = CompensationChamber(compensationChamberAddress);
    address[] memory paymentRequest = _compensationChamberContract.getUnpayedPaymentRequest();

    for (uint k = 0; k < paymentRequest.length; k++)
    {
      emit logPaymentRequestAddressAtSetup(paymentRequest[i]);
    }
  }

  event logPaymentRequestAtSetup(address paymentRequestAddress, uint value, address clearingMemberAddress);
  function getPaymentRequest(address _paymentRequestAddress)
  {
    PaymentRequest _paymentRequestContract = PaymentRequest(_paymentRequestAddress);
    if (_paymentRequestContract.isPayed() == false)
    {
      emit logPaymentRequestAtSetup(_paymentRequestAddress, _paymentRequestContract.getValue(), _paymentRequestContract.getClearingMember());
    }
  }

  function unpayedPaymentRequest() public
  {
    CompensationChamber _compensationChamberContract = CompensationChamber(compensationChamberAddress);
    _compensationChamberContract.unpayedPaymentRequest();
  }

  function test() public
  {
    paymentRequest(msg.sender, 10, msg.sender);
  }
}
