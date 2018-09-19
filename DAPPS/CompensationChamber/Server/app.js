var express = require('express');
var request = require('request');
var app = express();
var Web3 = require('web3');
var web3 = new Web3();
/******************************************************************************/

const PORT = 3000;
app.listen(PORT, function()
{
  console.log("app.js listening on port "+PORT+"!")
});
/**
 * The Portfolio class will contain the portfolio of a Member
 * once inserted all the instruments intro the class, we can calculate the var.
 */

/******************************************************************************/
/********************************* PORTFOLIO **********************************/
/******************************************************************************/
"use strict"
function Portfolio()
{
  this.instrumentArray = [];
  this.portfolioDailyRentability = [];
}
/**
 * Method to add new instruments to the portfolio, each instrument will be an object containing an historical data
 * Of this instrument, and how many assets of this type have the Member
 */

"use strict"
Portfolio.prototype.addInstrument = function(instrument)
{
  this.instrumentArray.push(instrument);
}

"use strict"
Portfolio.prototype.computeVaR = function(probability)
{
  probability = 1 - probability;

  var historicalDataLength = this.instrumentArray[0].historicalRentability.length;

  for( var i = 0; i < historicalDataLength; i++ )
  {
    var _rentability = 0;

    for( var j = 0; j < this.instrumentArray.length; j++ )
    {
      _rentability = _rentability + this.instrumentArray[j].getRentability(i);
    }

    this.portfolioDailyRentability.push(_rentability);
  }

  this.portfolioDailyRentability.sort(function(a,b){return a - b});

  var VaRPosition = parseInt(this.portfolioDailyRentability.length * probability);

  return this.portfolioDailyRentability[VaRPosition];
}

/******************************************************************************/
/********************************* INSTRUMENT *********************************/
/******************************************************************************/

function Instrument(_instrumentID, _amountOfAssets)
{
  this.instrumentID = _instrumentID;
  this.amountOfAssets = _amountOfAssets;
  this.historicalPriceChange = [];
}

Instrument.prototype.setActualPrice = function(_Price)
{
  this.actualPrice = _Price;
}

Instrument.prototype.setHistoricalPriceChange = function(_priceChange)
{
  this.historicalPriceChange.push(_priceChange);
}

Instrument.prototype.getInstrumentID = function()
{
  return this.instrumentID;
}

Instrument.prototype.computeVaR = function(probability)
{
  probability = 1 - probability;
  dataLength = this.historicalPriceChange.length;

  var escenarios = [];

  for (var i = 0; i < dataLength; i++)
  {
    escenarios.push(this.amountOfAssets * this.actualPrice * this.historicalPriceChange[i]);
  }
  escenarios.sort(function(a,b){return a - b});

  var VaRPosition = parseInt(escenarios.length * probability);
  return escenarios[VaRPosition];
}

/******************************************************************************/
/******************************* Interest Rate ********************************/
/******************************************************************************/

function InterestRate(_instrumentID, _nominal)
{
  this.instrumentID = _instrumentID;
  this.nominal = _nominal;
  this.historicalInterestRateChange = [];
}

InterestRate.prototype.setActualInterestRate = function(_interestRate)
{
  this.actualInterestRate = _interestRate;
}

InterestRate.prototype.setYesterdayInterestRate = function(_interestRate)
{
  this.yesterdayInterestRate = _interestRate;
}

InterestRate.prototype.computeMtM = function(_interestRate)
{
  console.log(this.nominal);
  console.log(this.actualInterestRate);
  console.log(this.yesterdayInterestRate);
  return this.nominal * (this.actualInterestRate - this.yesterdayInterestRate);
}


InterestRate.prototype.setHistoricalInterestRateChange = function(_interestRate)
{
  this.historicalInterestRateChange.push(_interestRate);
}

InterestRate.prototype.getInstrumentID = function()
{
  return this.instrumentID;
}

InterestRate.prototype.computeVaR = function(probability)
{
  probability = 1 - probability;
  dataLength = this.historicalInterestRateChange.length;

  var escenarios = [];

  for (var i = 0; i < dataLength; i++)
  {
    escenarios.push(this.nominal * this.actualInterestRate * this.historicalInterestRateChange[i]);
  }
  escenarios.sort(function(a,b){return a - b});

  var VaRPosition = parseInt(escenarios.length * probability);
  return escenarios[VaRPosition];
}

/******************************************************************************/
/********************************** Get Date **********************************/
/******************************************************************************/

function getDate(y, m, d)
{
  var today = new Date();
  var dd = today.getDate();
  var mm = today.getMonth()+1; //January is 0!
  var yyyy = today.getFullYear();

  if(dd<10)
  {
      dd = '0'+dd
  }

  if(mm<10)
  {
      mm = '0'+mm
  }
  yyyy = yyyy - y;
  mm = mm - m;
  dd = dd - d;

  var todayDate = yyyy + "-" + mm + "-" + dd;
  return todayDate;
}

/******************************************************************************/
/********************************** Server ************************************/
/******************************************************************************/

/******************************************************************************/
/************************************ VaR *************************************/
/******************************************************************************/

app.get("/", function(req, res)
{

  res.send("This is the Main page of the server to compute Initial Margins and Variation Margins <br>");
});

/**
 * This function performs the historical VaR calculation
 *
 * @param probability is the VaR probability expressed in parts per unit
 * @param portfolio are the financial instruments id followed by an `-` and the number of assets that the member have of this instrument
 *
 */
app.get("/computeVaR/:probability/:portfolio", function(req, res)
{
  var portfolio = req.params.portfolio;
  var probability = req.params.probability;
  var portfolioSplit = portfolio.split("-");

  var assetsArray = [];

  var portfolioObject = new Portfolio();

  for( var i = 0; i < portfolioSplit.length; i = i + 2)
  {
    assetsArray.push(new Instrument(portfolioSplit[i], parseInt(portfolioSplit[i+1])));
  }

  var k = 0;
  for( var i = 0; i < assetsArray.length; i++ )
  {
    var url = "https://api.iextrading.com/1.0/stock/"+assetsArray[i].getInstrumentID()+"/chart/5y";

    request(url, function (error, response, body)
    {
        var myJSON = JSON.parse(body);

        assetsArray[k].setInstrumentPrice(parseFloat(myJSON[myJSON.length-1].close));

        for(var j = 0; j<myJSON.length; j++)
        {
          assetsArray[k].setHistoricalRentability(parseFloat(myJSON[j].changePercent) / 100);
        }
        portfolioObject.addInstrument(assetsArray[k]);
        k = k + 1;
    });
  }
  setTimeout(function()
  {
    var VaR = portfolioObject.computeVaR(parseFloat(probability));
    res.send('The VaR of the Portfolio is '+VaR+'$');
  }, 15000);
});

/**
 * Bank of England Official Statistics
 *
 * The 3 month Euribor Instrument ID is IUDERB3
 * 3 month forward GBP/USD
 */
 app.get("/BOE/computeVaR/:probability/:nominalOrNumberOfAssets/:instrumentID/", function(req, res)
 {
   var nominalOrNumberOfAssets = parseFloat(req.params.nominalOrNumberOfAssets);
   var instrumentID = req.params.instrumentID;
   var probability = parseFloat(req.params.probability);

   var intRate = new InterestRate(instrumentID, nominalOrNumberOfAssets);

   var startDate = getDate(5,0,0);

   var k = 0;

   var url = "https://www.quandl.com/api/v3/datasets/BOE/"+intRate.getInstrumentID()+".json?api_key=aFBPpVBg4L5fMsc9BWHs&start_date="+startDate;
   request(url, function (error, response, body)
   {
       var myJSON = JSON.parse(body);

       var data = myJSON.dataset.data;

       intRate.setActualInterestRate(parseFloat(data[0][1]));

       var lastValue = parseFloat(data[data.length-1][1]);
       var actualValue = 0;

       var _historicalInterestRateChange = 0;


       for(var j = data.length - 2; j > 0; j--)
       {
         actualValue = parseFloat(data[j][1]);
         _historicalInterestRateChange = (actualValue - lastValue) / lastValue;
         intRate.setHistoricalInterestRateChange(_historicalInterestRateChange);
         lastValue = actualValue;
       }
       k = 1;
   });

   var url2 = "https://api.kraken.com/0/public/Ticker?pair=ETHGBP";
   var change;
   request(url2, function (error, response, body)
   {
       var myJSON = JSON.parse(body);
       change = myJSON.result.XETHZGBP.a[0];
   });
   setTimeout(function()
   {
     var VaR1 = Math.abs(intRate.computeVaR(parseFloat(probability)));
     var VaR2 = Math.abs(intRate.computeVaR(parseFloat(1 - probability)));
     console.log(VaR1+" "+VaR2);
     console.log(ToWEI(change, VaR1)+" "+ToWEI(change, VaR2));
     res.send(ToWEI(change, VaR1)+" "+ToWEI(change, VaR2));
   }, 7000);
 });


 app.get("/EUREX/computeVaR/:probability/:nominalOrNumberOfAssets/:instrumentID/", function(req, res)
 {
   //var portfolio = req.params.portfolio;
   var nominalOrNumberOfAssets = parseFloat(req.params.nominalOrNumberOfAssets);
   var instrumentID = req.params.instrumentID;
   var probability = parseFloat(req.params.probability);

   var intRate = new InterestRate(instrumentID, nominalOrNumberOfAssets);

   var startDate = getDate(5,0,0);

   var k = 0;

   var url = "https://www.quandl.com/api/v3/datasets/EUREX/"+intRate.getInstrumentID()+".json?api_key=aFBPpVBg4L5fMsc9BWHs&start_date="+startDate;
   request(url, function (error, response, body)
   {
       var myJSON = JSON.parse(body);

       var data = myJSON.dataset.data;

       intRate.setActualInterestRate(parseFloat(data[0][4]));

       var lastValue = parseFloat(data[data.length-1][4]);
       var actualValue = 0;

       var _historicalInterestRateChange = 0;

       for(var j = data.length - 2; j > 0; j--)
       {
         actualValue = parseFloat(data[j][4]);
         _historicalInterestRateChange = (actualValue - lastValue) / lastValue;
         intRate.setHistoricalInterestRateChange(_historicalInterestRateChange);
         lastValue = actualValue;
       }
       k = 1;
   });

   var url2 = "https://api.kraken.com/0/public/Ticker?pair=ETHEUR";
   var change;
   request(url2, function (error, response, body)
   {
       var myJSON = JSON.parse(body);
       change = myJSON.result.XETHZEUR.a[0];
   });
   setTimeout(function()
   {
     var VaR1 = Math.abs(intRate.computeVaR(parseFloat(probability)));
     var VaR2 = Math.abs(intRate.computeVaR(parseFloat(1 - probability)));
      res.send(ToWEI(change, VaR1)+" "+ToWEI(change, VaR2));
   }, 7000);
 });

 ToWEI = function(exchangeValue, price)
 {
   return parseInt(parseFloat(price)/parseFloat(exchangeValue)*1000000000000000000);
 }


 app.get("/CME/computeVaR/:probability/:nominalOrNumberOfAssets/:instrumentID/", function(req, res)
 {
   //var portfolio = req.params.portfolio;
   var nominalOrNumberOfAssets = parseFloat(req.params.nominalOrNumberOfAssets);
   var instrumentID = req.params.instrumentID;
   var probability = parseFloat(req.params.probability);

   var intRate = new InterestRate(instrumentID, nominalOrNumberOfAssets);

   var startDate = getDate(5,0,0);

   var k = 0;

   var url = "https://www.quandl.com/api/v3/datasets/CME/"+intRate.getInstrumentID()+".json?api_key=aFBPpVBg4L5fMsc9BWHs&start_date="+startDate;
   request(url, function (error, response, body)
   {
       var myJSON = JSON.parse(body);

       var data = myJSON.dataset.data;

       intRate.setActualInterestRate(parseFloat(data[0][6]));

       var lastValue = parseFloat(data[data.length-1][6]);
       var actualValue = 0;

       var _historicalInterestRateChange = 0;

       for(var j = data.length - 2; j > 0; j--)
       {
         actualValue = parseFloat(data[j][6]);
         _historicalInterestRateChange = (actualValue - lastValue) / lastValue;
         intRate.setHistoricalInterestRateChange(_historicalInterestRateChange);
         lastValue = actualValue;
       }
       k = 1;
   });
   var url2 = "https://api.kraken.com/0/public/Ticker?pair=ETHUSD";
   var change;
   request(url2, function (error, response, body)
   {
       var myJSON = JSON.parse(body);
       change = myJSON.result.XETHZUSD.a[0];
   });
   setTimeout(function()
   {
     var VaR1 = Math.abs(intRate.computeVaR(parseFloat(probability)));
     var VaR2 = Math.abs(intRate.computeVaR(parseFloat(1 - probability)));
      res.send(ToWEI(change, VaR1)+" "+ToWEI(change, VaR2));
   }, 7000);
 });

 /******************************************************************************/
 /************************************ MtM *************************************/
 /******************************************************************************/

 app.get("/BOE/computeMtM/:nominalOrNumberOfAssets/:instrumentID/", function(req, res)
 {
   //var portfolio = req.params.portfolio;
   var nominalOrNumberOfAssets = parseFloat(req.params.nominalOrNumberOfAssets);
   var instrumentID = req.params.instrumentID;
   var probability = parseFloat(req.params.probability);

   var intRate = new InterestRate(instrumentID, nominalOrNumberOfAssets);

   var startDate = getDate(5,0,0);

   var k = 0;

   var url = "https://www.quandl.com/api/v3/datasets/BOE/"+intRate.getInstrumentID()+".json?api_key=aFBPpVBg4L5fMsc9BWHs&start_date="+startDate;
   request(url, function (error, response, body)
   {
       var myJSON = JSON.parse(body);

       var data = myJSON.dataset.data;

       intRate.setActualInterestRate(parseFloat(data[0][1]));
       intRate.setYesterdayInterestRate(parseFloat(data[1][1]));
   });

   var url2 = "https://api.kraken.com/0/public/Ticker?pair=ETHGBP";
   var change;
   request(url2, function (error, response, body)
   {
       var myJSON = JSON.parse(body);
       change = myJSON.result.XETHZGBP.a[0];
   });
   setTimeout(function()
   {
     var a = intRate.computeMtM()
     if(parseFloat(a) > 0)
     {
       res.send("0."+ToWEI(change, a)); // Revisar // Return this in wei
     }
     else
     {
       res.send("1."+ToWEI(change, a)); // Revisar // Return this in wei
     }
   }, 7000);
 });



 app.get("/CME/computeMtM/:nominalOrNumberOfAssets/:instrumentID/", function(req, res)
 {
   //var portfolio = req.params.portfolio;
   var nominalOrNumberOfAssets = parseFloat(req.params.nominalOrNumberOfAssets);
   var instrumentID = req.params.instrumentID;
   var probability = parseFloat(req.params.probability);

   var intRate = new InterestRate(instrumentID, nominalOrNumberOfAssets);

   var startDate = getDate(5,0,0);

   var k = 0;

   var url = "https://www.quandl.com/api/v3/datasets/BOE/"+intRate.getInstrumentID()+".json?api_key=aFBPpVBg4L5fMsc9BWHs&start_date="+startDate;
   request(url, function (error, response, body)
   {
       var myJSON = JSON.parse(body);

       var data = myJSON.dataset.data;

       intRate.setActualInterestRate(parseFloat(data[0][6]));
       intRate.setYesterdayInterestRate(parseFloat(data[1][6]));
   });
   var url2 = "https://api.kraken.com/0/public/Ticker?pair=ETHUSD";
   var change;
   request(url2, function (error, response, body)
   {
       var myJSON = JSON.parse(body);
       change = myJSON.result.XETHZUSD.a[0];
   });
   setTimeout(function()
   {
     var a = intRate.computeMtM()
     if(parseFloat(a) > 0)
     {
       res.send("0."+ToWEI(change, a)); // Revisar // Return this in wei
     }
     else
     {
       res.send("1."+ToWEI(change, a)); // Revisar // Return this in wei
     }
   }, 7000);
 });


 app.get("/EUREX/computeMtM/:nominalOrNumberOfAssets/:instrumentID/", function(req, res)
 {
   //var portfolio = req.params.portfolio;
   var nominalOrNumberOfAssets = parseFloat(req.params.nominalOrNumberOfAssets);
   var instrumentID = req.params.instrumentID;
   var probability = parseFloat(req.params.probability);

   var intRate = new InterestRate(instrumentID, nominalOrNumberOfAssets);

   var startDate = getDate(5,0,0);

   var k = 0;

   var url = "https://www.quandl.com/api/v3/datasets/BOE/"+intRate.getInstrumentID()+".json?api_key=aFBPpVBg4L5fMsc9BWHs&start_date="+startDate;
   request(url, function (error, response, body)
   {
       var myJSON = JSON.parse(body);

       var data = myJSON.dataset.data;

       intRate.setActualInterestRate(parseFloat(data[0][4]));
       intRate.setYesterdayInterestRate(parseFloat(data[1][4]));
   });
   var url2 = "https://api.kraken.com/0/public/Ticker?pair=ETHEUR";
   var change;
   request(url2, function (error, response, body)
   {
       var myJSON = JSON.parse(body);
       change = myJSON.result.XETHZEUR.a[0];
   });
   setTimeout(function()
   {
     var a = intRate.computeMtM()
     if(parseFloat(a) > 0)
     {
       res.send("0."+ToWEI(change, a)); // Revisar // Return this in wei
     }
     else
     {
       res.send("1."+ToWEI(change, a)); // Revisar // Return this in wei
     }
   }, 7000);
 });
