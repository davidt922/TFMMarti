import { default as Web3} from 'web3';
import {BigNumber} from 'bignumber.js';

export default class PaymentRequest
{
  constructor()
  {
    this.paymentRequest = [];
  }

  addNewPaymentRequest(_transactionResult)
  {
    if (account == _transactionResult.args.clearingMemberAddress)
    {
      var args = _transactionResult.args;
      var paymentRequest = {paymentRequestAddress: args.paymentRequestAddress,clearingMemberAddress: args.clearingMemberAddress, value: new BigNumber(args.value).toNumber()};
      this.paymentRequest.push(paymentRequest);

      if (confirm("You have to pay "+ paymentRequest.value/1000000000000000000))
      {
        this.payPaymentRequest(paymentRequest.paymentRequestAddress);
      }
    }
  }
  addNewPaymentRequestAtSetup(_transactionResult)
  {
    if (account == _transactionResult.args.clearingMemberAddress)
    {
      var args = _transactionResult.args;
      var paymentRequest = {paymentRequestAddress: args.paymentRequestAddress,clearingMemberAddress: args.clearingMemberAddress, value: new BigNumber(args.value).toNumber()};
      this.paymentRequest.push(paymentRequest);
    }
  }
  payPaymentRequest(_paymentRequestAddress)
  {
    var paymentReq = this.paymentRequest.find(function(paymentRequest)
    {
        return paymentRequest.paymentRequestAddress == _paymentRequestAddress;
    });
    App.payPaymentRequest(paymentReq.paymentRequestAddress, paymentReq.value);
  }
  checkIfPayed(_ispayed, _paymentRequestAddress)
  {
    if(_ispayed == true)
    {
      var paymentReq = this.paymentRequest.find(function(paymentRequest)
      {
          return paymentRequest.paymentRequestAddress == _paymentRequestAddress;
      });
      this.paymentRequest.splice(paymentReq,1);
      alert("Payment request: "+_paymentRequestAddress+" has been payed");
    }
  }

  getUnpayedTransactions()
  {
    return this.paymentRequest;
  }
}
