pragma solidity ^0.4.24;

import "./usingOraclize.sol";
import "./Derivative.sol";
/**
 * Allow Slice strings
 */
import "./strings.sol";

import "./Utils.sol";


contract MarketData is usingOraclize
{
  mapping(bytes32 => uint16) queryIdToFunctionNumber;
  mapping(bytes32 => address) queryIdToContractAddressThatHaveCalledTheFunction;

  address compensationChamberAddress;

  uint gasLimit = 4000000;

  string ipPort = "http://92.176.214.196:3000";

  constructor() public payable
  {
    OAR = OraclizeAddrResolverI(0x6f485c8bf6fc43ea212e93bbf8ce046c7f1cb475);
    compensationChamberAddress = msg.sender;
  }

  function getIMFutureBOE (bytes32 _nominalBytes32, bytes32 _instrumentIDBytes32) public payable
  {
    if (oraclize_getPrice("URL") < this.balance)
    {
      string memory _nominal = Utils.bytes32ToString(_nominalBytes32);
      string memory _instrumentID = Utils.bytes32ToString(_instrumentIDBytes32);

      string memory URL = strConcat(ipPort,"/BOE/computeVaR/");
      //string memory URL = "json(https://tidy-jellyfish-22.localtunnel.me/BOE/computeVaR/";
      string memory query1 = "0.95";
      string memory query2_4 = "/";
      string memory query6 = "/";

      string memory _query = strConcat(URL, query1, query2_4, _nominal, query2_4);
      string memory query = strConcat(_query, _instrumentID, query6);
      bytes32 queryID = oraclize_query("URL",query, gasLimit);
      queryIdToContractAddressThatHaveCalledTheFunction[queryID] = msg.sender;
      queryIdToFunctionNumber[queryID] = 1;
    }
  }

  function getIMFutureEUREX (bytes32 _nominalBytes32, bytes32 _instrumentIDBytes32) public payable
  {
    if (oraclize_getPrice("URL") < this.balance)
    {
      string memory _nominal = Utils.bytes32ToString(_nominalBytes32);
      string memory _instrumentID = Utils.bytes32ToString(_instrumentIDBytes32);

      string memory URL = strConcat(ipPort,"/EUREX/computeVaR/");
      string memory query1 = "0.95";
      string memory query2_4 = "/";
      string memory query6 = "/";

      string memory _query = strConcat(URL, query1, query2_4, _nominal, query2_4);
      string memory query = strConcat(_query, _instrumentID, query6);
      bytes32 queryID = oraclize_query("URL",query, gasLimit);
      queryIdToContractAddressThatHaveCalledTheFunction[queryID] = msg.sender;
      queryIdToFunctionNumber[queryID] = 1;
    }
  }

  function getIMFutureCME (bytes32 _nominalBytes32, bytes32 _instrumentIDBytes32) public payable
  {
    if (oraclize_getPrice("URL") < this.balance)
    {
      string memory _nominal = Utils.bytes32ToString(_nominalBytes32);
      string memory _instrumentID = Utils.bytes32ToString(_instrumentIDBytes32);

      string memory URL = strConcat(ipPort,"/CME/computeVaR/");
      string memory query1 = "0.95";
      string memory query2_4 = "/";
      string memory query6 = "/";

      string memory _query = strConcat(URL, query1, query2_4, _nominal, query2_4);
      string memory query = strConcat(_query, _instrumentID, query6);
      bytes32 queryID = oraclize_query("URL",query, gasLimit);
      queryIdToContractAddressThatHaveCalledTheFunction[queryID] = msg.sender;
      queryIdToFunctionNumber[queryID] = 1;
    }
  }

  function getVMFutureBOE (bytes32 _nominalBytes32, bytes32 _instrumentIDBytes32) public payable
  {
    if (oraclize_getPrice("URL") < this.balance)
    {
      string memory _nominal = Utils.bytes32ToString(_nominalBytes32);
      string memory _instrumentID = Utils.bytes32ToString(_instrumentIDBytes32);

      string memory URL = strConcat(ipPort,"/BOE/computeMtM/");
      //string memory URL = "json(https://tidy-jellyfish-22.localtunnel.me/BOE/computeVaR/";
      string memory query1 = "0.95";
      string memory query2_4 = "/";
      string memory query6 = "/";

      string memory query = strConcat(URL, _nominal, query2_4, _instrumentID, query6);
      bytes32 queryID = oraclize_query("URL",query, gasLimit);
      queryIdToContractAddressThatHaveCalledTheFunction[queryID] = msg.sender;
      queryIdToFunctionNumber[queryID] = 2;
    }
  }

  function getVMFutureEUREX (bytes32 _nominalBytes32, bytes32 _instrumentIDBytes32) public payable
  {
    if (oraclize_getPrice("URL") < this.balance)
    {
      string memory _nominal = Utils.bytes32ToString(_nominalBytes32);
      string memory _instrumentID = Utils.bytes32ToString(_instrumentIDBytes32);

      string memory URL = strConcat(ipPort,"/EUREX/computeMtM/");
      string memory query1 = "0.95";
      string memory query2_4 = "/";
      string memory query6 = "/";

      string memory query = strConcat(URL, _nominal, query2_4, _instrumentID, query6);
      bytes32 queryID = oraclize_query("URL",query, gasLimit);
      queryIdToContractAddressThatHaveCalledTheFunction[queryID] = msg.sender;
      queryIdToFunctionNumber[queryID] = 2;
    }
  }

  function getVMFutureCME (bytes32 _nominalBytes32, bytes32 _instrumentIDBytes32) public payable
  {
    if (oraclize_getPrice("URL") < this.balance)
    {
      string memory _nominal = Utils.bytes32ToString(_nominalBytes32);
      string memory _instrumentID = Utils.bytes32ToString(_instrumentIDBytes32);

      string memory URL = strConcat(ipPort,"/CME/computeMtM/");
      string memory query1 = "0.95";
      string memory query2_4 = "/";
      string memory query6 = "/";

      string memory query = strConcat(URL, _nominal, query2_4, _instrumentID, query6);
      bytes32 queryID = oraclize_query("URL",query, gasLimit);
      queryIdToContractAddressThatHaveCalledTheFunction[queryID] = msg.sender;
      queryIdToFunctionNumber[queryID] = 2;
    }
  }

  function __callback (bytes32 myid, string result)
  {
    if (msg.sender != oraclize_cbAddress())
    {
      revert();
    }
    uint16 functionNumber = queryIdToFunctionNumber[myid];
    address ownerAddress= queryIdToContractAddressThatHaveCalledTheFunction[myid];

    Derivative _derivative;
    // Initial Margin
    if (functionNumber == 1)
    {
      uint[2] memory weiValue = Utils.stringToUintArray2(result);
      _derivative = Derivative(ownerAddress);
      _derivative.setIM(weiValue[0], weiValue[1]);
    } // Variation margin
    else if (functionNumber == 2)
    {
      _derivative = Derivative(ownerAddress);
      _derivative.setVM(Utils.stringToInt(result));
    }
  }
}
