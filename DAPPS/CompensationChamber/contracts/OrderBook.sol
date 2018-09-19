pragma experimental ABIEncoderV2;

import "./QuickSortOrder.sol";
import "./Market.sol";
import "./Utils.sol";

contract OrderBook is QuickSortOrder
{
  Utils.instrumentType instType;

  bytes32 instrumentID;
  Utils.market market;
  uint settlementTimestamp;

  address marketAddress;

  // Ask are sell orders
  Utils.order[] askOrders;
  // BID are buy orders
  Utils.order[] bidOrders;

  modifier onlyMarket()
  {
    require (marketAddress == msg.sender);
    _;
  }

  constructor(bytes32 _instrumentID, Utils.market _market, Utils.instrumentType _instrumentType, uint _settlementTimestamp) public
  {
    instrumentID = _instrumentID;
    market = _market;
    instType = _instrumentType;
    marketAddress = msg.sender;
    settlementTimestamp = _settlementTimestamp;
  }

  function addBuyOrder(uint16 _quantity, uint16 _price) public onlyMarket
  {
    if (askOrders.length != 0)
    {
      uint i = 0;
      Market _marketContract = Market(marketAddress);
      orderIncreasing(askOrders);
      while (_price >= askOrders[i].price && _quantity > 0 && askOrders.length != 0)
      {
        if (_quantity >= askOrders[i].quantity)
        {
          if (instType == Utils.instrumentType.future)
          {
            _marketContract.addFutureToCCP(tx.origin, askOrders[i].clearingMemberAddress, instrumentID, Utils.uint16ToBytes(askOrders[i].quantity), Utils.uint16PriceToBytes32(askOrders[i].price), settlementTimestamp, market);
          }
          else if (instType == Utils.instrumentType.swap)
          {
            //_marketContract.addSwapToCCP(tx.origin, askOrders[i].clearingMemberAddress, instrumentID, Utils.uint16ToBytes(askOrders[i].quantity), Utils.uint16PriceToBytes32(askOrders[i].price), settlementTimestamp, market);
          }
        }
        else
        {
          if (instType == Utils.instrumentType.future)
          {
            _marketContract.addFutureToCCP(tx.origin, askOrders[i].clearingMemberAddress, instrumentID, Utils.uint16ToBytes(_quantity), Utils.uint16PriceToBytes32(askOrders[i].price), settlementTimestamp, market);
          }
          else if (instType == Utils.instrumentType.swap)
          {
            //_marketContract.addSwapToCCP(tx.origin, askOrders[i].clearingMemberAddress, instrumentID, Utils.uint16ToBytes(_quantity), Utils.uint16PriceToBytes32(askOrders[i].price), settlementTimestamp, market);
          }
        }
        (i, _quantity) = removeAskFromOrderBook(i, _quantity);
        i++;

        if(i >= askOrders.length)
        {
          break;
        }
      }
    }
    if (_quantity > 0)
    {
      addBidToOrderBook(_quantity, _price);
    }
  }

  function addSellOrder(uint16 _quantity, uint16 _price) public onlyMarket
  {
    if (bidOrders.length != 0)
    {
      uint i = 0;
      Market _marketContract = Market(marketAddress);
      orderDecreasing(bidOrders);
      while (_price <= bidOrders[i].price && _quantity > 0 && bidOrders.length != 0)
      {
        if (_quantity >= bidOrders[i].quantity)
        {
          if (instType == Utils.instrumentType.future)
          {
            _marketContract.addFutureToCCP(bidOrders[i].clearingMemberAddress, tx.origin, instrumentID, Utils.uint16ToBytes(bidOrders[i].quantity), Utils.uint16PriceToBytes32(bidOrders[i].price), settlementTimestamp, market);
          }
          else if (instType == Utils.instrumentType.swap)
          {
            //_marketContract.addSwapToCCP(bidOrders[i].clearingMemberAddress, tx.origin, instrumentID, Utils.uint16ToBytes(bidOrders[i].quantity), Utils.uint16PriceToBytes32(bidOrders[i].price), settlementTimestamp, market);
          }
        }
        else
        {
          if (instType == Utils.instrumentType.future)
          {
            _marketContract.addFutureToCCP(bidOrders[i].clearingMemberAddress, tx.origin, instrumentID, Utils.uint16ToBytes(_quantity), Utils.uint16PriceToBytes32(bidOrders[i].price), settlementTimestamp, market);
          }
          else if (instType == Utils.instrumentType.swap)
          {
            //_marketContract.addSwapToCCP(bidOrders[i].clearingMemberAddress, tx.origin, instrumentID, Utils.uint16ToBytes(_quantity), Utils.uint16PriceToBytes32(bidOrders[i].price), settlementTimestamp, market);
          }
        }
        (i, _quantity) = removeBidFromOrderBook(i, _quantity);
        i++;

        if(i >= askOrders.length)
        {
          break;
        }
      }
    }

    if (_quantity > 0)
    {
        addAskToOrderBook(_quantity, _price);
    }
  }
  function addBidToOrderBook(uint16 _quantity, uint16 _price) internal
  {
      bidOrders.push(Utils.order(tx.origin, _quantity, block.timestamp,  _price));
      Market _marketContract = Market(marketAddress);
      _marketContract.OrderEvent(instrumentID, _quantity, _price, Utils.side.buy, Utils.orderType.add);
  }

  function addAskToOrderBook(uint16 _quantity, uint16 _price) internal
  {
      askOrders.push(Utils.order(tx.origin, _quantity, block.timestamp,  _price));
      Market _marketContract = Market(marketAddress);
      _marketContract.OrderEvent(instrumentID, _quantity, _price, Utils.side.sell, Utils.orderType.add);
  }


  function removeAskFromOrderBook(uint i, uint16 quantity) returns (uint _i, uint16 _quantity)
  {
    Market _marketContract = Market(marketAddress);

    if (quantity >= askOrders[i].quantity)
    {
      quantity = quantity - askOrders[i].quantity;
      _marketContract.OrderEvent(instrumentID, askOrders[i].quantity, askOrders[i].price, Utils.side.sell, Utils.orderType.remove);
      Utils.removeOrder(askOrders, i);
      if (i != 0)
      {
        i--;
      }
    }
    else if (quantity < askOrders[i].quantity)
    {
      askOrders[i].quantity = askOrders[i].quantity - quantity;
      _marketContract.OrderEvent(instrumentID, quantity, askOrders[i].price, Utils.side.sell, Utils.orderType.remove);
      quantity = 0;
    }
    _i = i;
    _quantity = quantity;
  }

  function removeBidFromOrderBook(uint i, uint16 quantity) returns (uint _i, uint16 _quantity)
  {
    Market _marketContract = Market(marketAddress);

    if (quantity >= bidOrders[i].quantity)
    {
      quantity = quantity - bidOrders[i].quantity;
      _marketContract.OrderEvent(instrumentID, bidOrders[i].quantity, bidOrders[i].price, Utils.side.buy, Utils.orderType.remove);
      Utils.removeOrder(bidOrders, i);
      if (i != 0)
      {
        i--;
      }
    }
    else if (quantity < bidOrders[i].quantity)
    {
      bidOrders[i].quantity = bidOrders[i].quantity - quantity;
      _marketContract.OrderEvent(instrumentID, quantity, bidOrders[i].price, Utils.side.buy, Utils.orderType.remove);
      quantity = 0;
    }
    _i = i;
    _quantity = quantity;
  }

    function getAskOrdersLength() returns (uint)
    {
      return askOrders.length;
    }

    function getBidOrdersLength() returns (uint)
    {
      return bidOrders.length;
    }

    function getAskOrders(uint i) public constant returns (uint16 _quantity, uint16 _price)
    {
        _quantity = askOrders[i].quantity;
        _price = askOrders[i].price;
    }

    function getBidOrders(uint i) public constant returns (uint16 _quantity, uint16 _price)
    {
        _quantity = bidOrders[i].quantity;
        _price = bidOrders[i].price;
    }
}
