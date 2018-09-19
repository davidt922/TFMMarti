pragma experimental ABIEncoderV2;

import "./Utils.sol";
/**
 * Derivative is an abstract contract: Contracts are marked as abstract when at
 * least one of their functions lacks an implementation as in the following
 * example (note that the function declaration header is terminated by ;):
 */

 contract Derivative
 {
   bytes32 instrumentID;
   Utils.market market;

   address marketDataAddress;
   address compensationChamberAddress;

   uint settlementTimeStamp;
   uint novationTimeStamp;

   bytes32 price;

   // initialMargin store the initial margin payment value of each counterpart
   mapping (address => uint) initialMargin;
   /**
   * Modifiers
   */

   modifier onlyMarketData
   {
      require(msg.sender == marketDataAddress);
      _;
   }

   modifier onlyChamber
   {
      require(msg.sender == compensationChamberAddress);
      _;
   }

  constructor (bytes32 _instrumentID, uint _settlementTimestamp, address _marketDataAddress, Utils.market _market, bytes32 _price) public
  {
        instrumentID = _instrumentID;
        market = _market;

        marketDataAddress = _marketDataAddress;
        compensationChamberAddress = msg.sender;
        price = _price;

        settlementTimeStamp = _settlementTimestamp;
        novationTimeStamp = block.timestamp;
  }

  function getTheContractCounterparts() public returns(address[2]);
  function setIM(uint, uint) onlyMarketData public;
  function computeVM() public onlyChamber;
  function setVM(int) onlyMarketData public;

  function initialMarginPayment (address memberAddress) payable
  {
    initialMargin[memberAddress] == msg.value;
  }

  function settlement() onlyChamber public;

 }
