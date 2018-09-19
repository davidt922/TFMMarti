pragma experimental ABIEncoderV2;

import "./Derivative.sol";
import "./MarketData.sol";
import "./Utils.sol";
import "./PaymentRequest.sol";
  import "./CompensationChamber.sol";
contract Future is Derivative
{
  address longMemberAddress; // The one who will have to buy the asset (subyacente) in the settlementTimestamp
  address shortMemberAddress; // The one who will have to sell the asset (subyacente) in the settlementTimestamp
  bytes32 amount; // Amount of the subyacent asset that they have to trade at settlementTimestamp

  constructor (address _longMemberAddress, address _shortMemberAddress, bytes32 _instrumentID, bytes32 _amount, bytes32 _price, uint _settlementTimestamp, address _marketDataAddress, Utils.market _market) Derivative(_instrumentID, _settlementTimestamp, _marketDataAddress, _market, _price) public payable
  {
    require (msg.value >= 1 ether);

    longMemberAddress = _longMemberAddress;
    shortMemberAddress = _shortMemberAddress;
    amount = _amount;
    computeIM();
    //setIM(100000000000000, 30000000000000);
  }

  function computeIM() private
  {
    MarketData _marketDataContract = MarketData(marketDataAddress);

    if (market == Utils.market.BOE) // Bank of england
    {
      _marketDataContract.getIMFutureBOE.value(1 ether)(amount, instrumentID);
    }
    else if (market == Utils.market.EUREX) // https://www.quandl.com/data/EUREX-EUREX-Futures-Data
    {
      _marketDataContract.getIMFutureEUREX.value(1 ether)(amount, instrumentID);
    }
    else if (market == Utils.market.CME) // Chicago Mercantile Exchanges // https://www.quandl.com/data/CME-Chicago-Mercantile-Exchange-Futures-Data
    {
      _marketDataContract.getIMFutureCME.value(1 ether)(amount, instrumentID);
    }
  }

  function getTheContractCounterparts() public returns(address[2])
  {
      return [longMemberAddress, shortMemberAddress];
  }

  function setIM(uint longMemberInitialMarginInWei, uint shortMemberInitialMarginInWei)/* onlyMarketData*/ public
  {
      initialMargin[longMemberAddress] = longMemberInitialMarginInWei;
      initialMargin[shortMemberAddress] = shortMemberInitialMarginInWei;

      //CompensationChamber _compensationChamberContract = CompensationChamber(compensationChamberAddress);
      //_compensationChamberContract.paymentRequest(longMemberInitialMarginInWei, longMemberAddress);
      //  _compensationChamberContract.paymentRequest(shortMemberInitialMarginInWei, shortMemberAddress);
      new PaymentRequest(longMemberInitialMarginInWei, longMemberAddress, compensationChamberAddress, Utils.paymentType.initialMargin);
      new PaymentRequest(shortMemberInitialMarginInWei, shortMemberAddress, compensationChamberAddress, Utils.paymentType.initialMargin);
  }


  function setVM(int MtMChangeForLongMember) onlyMarketData public
  {
      Utils.variationMarginChange[2] memory ret;
      int MtMChangeForShortMember = MtMChangeForLongMember * -1;

      ret[0] = Utils.variationMarginChange(longMemberAddress, MtMChangeForLongMember);
      ret[1] = Utils.variationMarginChange(shortMemberAddress, MtMChangeForShortMember);

      CompensationChamber _compensationChamberContract = CompensationChamber(compensationChamberAddress);
      _compensationChamberContract.variationMargin(ret[0], ret[1]);

  }

  function computeVM() public onlyChamber
  {
    MarketData _marketDataContract = MarketData(marketDataAddress);

      if (market == Utils.market.BOE) // Bank of england
      {
        _marketDataContract.getIMFutureBOE.value(1 ether)(amount, instrumentID);
      }
      else if (market == Utils.market.EUREX) // https://www.quandl.com/data/EUREX-EUREX-Futures-Data
      {
        _marketDataContract.getIMFutureEUREX.value(1 ether)(amount, instrumentID);
      }
      else if (market == Utils.market.CME) // Chicago Mercantile Exchanges // https://www.quandl.com/data/CME-Chicago-Mercantile-Exchange-Futures-Data
      {
        _marketDataContract.getIMFutureCME.value(1 ether)(amount, instrumentID);
      }

  }
  function settlement() onlyChamber public
  {
    longMemberAddress.transfer(uint(initialMargin[longMemberAddress]*9/10));
    shortMemberAddress.transfer(uint(initialMargin[longMemberAddress]*9/10));

    selfdestruct(compensationChamberAddress);

  }
}
