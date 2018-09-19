import { default as Web3} from 'web3';
import {BigNumber} from 'bignumber.js';
window.accountDialog = {};

//$(function(){}); is equals to $(document).ready(function(){})
$( function()
{
  var  form;

  accountDialog = $( "#account-dialog" ).dialog(
  {
    autoOpen: false,
    height: 400,
    width: 750,
    modal: true,
    buttons:
    {
      close: function()
      {
        $( this ).dialog( "close" );
      }
    }
  });

});

window.getAccountBalance = async function(_account)
{
  const promisify = (inner) =>
    new Promise((resolve, reject) =>
      inner((err, res) => {
        if (err) { reject(err) }
        resolve(res);
      })
    );

  const getBalance = (account, at) =>
    promisify(cb => web3.eth.getBalance(account, at, cb));

  // use getBalance
  const bigNumberBalance = await getBalance(_account);
  return new BigNumber(bigNumberBalance).toNumber();
}

window.openAccountDialog = function()
{
  $("#unpayedTransactionsBody").empty();
  var unpayedPaymentRequest = paymentRequest.getUnpayedTransactions();

  for (var i = 0; i < unpayedPaymentRequest.length; i++)
  {
    $("#unpayedTransactionsBody").append("<tr><td><button onclick='paymentRequest.payPaymentRequest("+unpayedPaymentRequest[i].paymentRequestAddress+")'>"+unpayedPaymentRequest[i].paymentRequestAddress+"</button></td><td>"+unpayedPaymentRequest[i].value/1000000000000000000+"</td></tr>");
  }

  accountDialog.dialog(
  {
    title: "Account "+account,
    buttons:
    {
      Close: function()
      {
        accountDialog.dialog( "close" );
      },
    }
  }).dialog( "open" );
}
