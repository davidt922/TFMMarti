import {BigNumber} from 'bignumber.js';
import { default as Web3} from 'web3';
export default class OrderBook
{
  constructor (instrumentID)
  {
    this.instrumentID = instrumentID;
    this.ask = [];
    this.bid = [];
    this.addOrderBookToHTML();
  }

  order(solOrderTx)
  {
    var args = solOrderTx.args;
    var price = IntToPrice(args.price);
    var quantity = new BigNumber(args.quantity).toNumber();
    // side is buy = 0 or sell = 1 (type int)
    var side = new BigNumber(args.side).toNumber();
    // type is add = 0 or remove = 1 (type int)
    var type = new BigNumber(args.orderType).toNumber();

    if (type == 0)
    {
      this.addOrder(quantity, price, side);
    }
    else if (type == 1)
    {
      this.removeOrder(quantity, price, side);
    }

  }
  orderSetup(solOrderTx)
  {
    var args = solOrderTx.args;
    var txOrigin = args.txOrigin;

    if (txOrigin == account)
    {
      this.order(solOrderTx);
    }

  }

  addOrder(_quantity, _price, side)
  {
    // side is the side of the order 0 for buy order (bid) and 1 for sell order (ask)
    if (side == 0)
    {
      var bidOrder = this.bid.find(function(order)
      {
          return order.price == _price;
      });

      // if some orders exist at this price
      if (bidOrder != undefined)
      {
        bidOrder.quantity = bidOrder.quantity + _quantity;
      }
      else // there is no order at this price in the orderbook
      {
        this.bid.push({price: _price, quantity: _quantity});
      }
    }
    else if (side == 1)
    {
      var askOrder = this.ask.find(function(order)
      {
          return order.price == _price;
      });

      // if some orders exist at this price
      if (askOrder != undefined)
      {
        askOrder.quantity = askOrder.quantity + _quantity;
      }
      else // there is no order at this price in the orderbook
      {
        this.ask.push({price: _price, quantity: _quantity});
      }
    }
    this.updateOrderBook();
  }

  removeOrder(_quantity, _price, side)
  {
    // side is the side of the order 1 for buy order (bid) and 0 for sell order (ask)
    if (side == 0)
    {
      var bidOrder = this.bid.find(function(order)
      {
          return order.price == _price;
      });

      // if some orders exist at this price
      if (bidOrder != undefined)
      {
        bidOrder.quantity = bidOrder.quantity - _quantity;

        if (bidOrder.quantity <= 0)
        {
          this.bid.splice(bidOrder, 1);
        }
      }
      else // there is no order at this price in the orderbook
      {
        console.error("The order have to exist to be removed");
      }
    }
    else if (side == 1)
    {
      var askOrder = this.ask.find(function(order)
      {
          return order.price == _price;
      });

      // if some orders exist at this price
      if (askOrder != undefined)
      {
        askOrder.quantity = askOrder.quantity - _quantity;

        if (askOrder.quantity <= 0)
        {
          this.ask.splice(askOrder, 1);
        }
      }
      else // there is no order at this price in the orderbook
      {
        console.error("The order have to exist to be removed");
      }
    }
    this.updateOrderBook();
  }

  updateOrderBook()
  {
    $("#table"+this.instrumentID).find("tbody").empty();

    if (this.ask.length > 0)
    {
      this.ask.sort(function(a,b) {return (priceToInt(a.price) > priceToInt(b.price)) ? 1 : ((priceToInt(b.price) > priceToInt(a.price)) ? -1 : 0);} );

      var j = this.ask.length > 4 ? 3 : this.ask.length - 1;

      for (var i = j; i >= 0; i--)
      {
        $("#table"+this.instrumentID).find('tbody').append("<tr> <td></td> <td>"+this.ask[i].price+"</td> <td>"+this.ask[i].quantity+"</td> </tr>");
      }
    }

    if (this.bid.length > 0)
    {
      this.bid.sort(function(a,b) {return (priceToInt(a.price) < priceToInt(b.price)) ? 1 : ((priceToInt(b.price) < priceToInt(a.price)) ? -1 : 0);} );

      var j = this.bid.length > 4 ? 4 : this.bid.length;

      for (var i = 0; i < j; i++)
      {
        $("#table"+this.instrumentID).find('tbody').append("<tr> <td>"+this.bid[i].quantity+"</td> <td>"+this.bid[i].price+"</td> <td></td> </tr>");
      }
    }
  }

  addOrderBookToHTML()
  {
    $("#orderBooks").append("<div class='orderBook' id='orderBook"+this.instrumentID+"'></div>");
    $("#orderBook"+this.instrumentID).append("<div>"+this.instrumentID.toUpperCase()+"</div>");
    $("#orderBook"+this.instrumentID).append("<div class='orders' id='orders"+this.instrumentID+"'></div>");
    $("#orderBook"+this.instrumentID).append("<div><button class='twoButtons' style='background:#ff0000;' id='sell"+this.instrumentID+"'>SELL</button><button class='twoButtons' id='buy"+this.instrumentID+"'>BUY</button></div>");


    // add table
    $("#orders"+this.instrumentID).append("<table id='table"+this.instrumentID+"'><thead><tr><th>BUY</th><th>Price</th><th>SELL</th></tr></thead><tbody></tbody></table>");
    var self = this;
    $("#buy"+this.instrumentID).click(function(){
      createDialog(self.instrumentID, "BUY"); // 0 = buy
    });

    $("#sell"+this.instrumentID).click(function(){
      createDialog(self.instrumentID, "SELL"); // 1 = sell
    });
  }

}
exports.OrderBook = OrderBook;

var doc = document;
window.createDialog = function(instrumentID, side)
{
  dialog.dialog({title: side+" "+instrumentID}).dialog(
  {
    buttons:
    {
      ADD_ORDER: function()
      {
        var _quantity = parseInt(document.getElementById("quantity").value);
        var _price = priceToInt(document.getElementById("price").value); // The input of the smart contract is the price integer value moving the decimal point 3 positions to the right
        App.addOrderToBlockchain(instrumentID, _quantity, _price, side);
        dialog.dialog( "close" );
      },
      Cancel: function()
      {
        dialog.dialog( "close" );
      }
    }
  }).dialog( "open" );
};

window.sideToInt = function(string)
{
  if (string.toLowerCase() == "buy")
  {
    return 0;
  }
  else if (string.toLowerCase() == "sell")
  {
    return 1;
  }
}

window.IntToSide = function(int)
{
  if (int == 0)
  {
    return "BUY";
  }
  else if (int == 1)
  {
    return "SELL";
  }
}

window.priceToInt = function (price)
{
  return parseInt(price*1000);
}
window.IntToPrice = function (int)
{
  var stringNum = new BigNumber(int).toNumber().toString();

  var real;
  var decimal;

  if (stringNum.length < 4)
  {
    real = 0;
    var zeros = 3 - stringNum.length;
    var zeroString = "000";
    decimal = zeroString.substring(0,zeros)+stringNum;
  }
  else
  {
    real = stringNum.substring(0, stringNum.length-3);
    decimal = stringNum.substring(stringNum.length-3);
  }
  return real+"."+decimal;
}
