var Market1 = artifacts.require("./Market.sol");

module.exports = function(deployer, network, accounts)
{
  // Deploys the OraclizeTest contract and funds it with 0.5 ETH
// The contract needs a balance > 0 to communicate with Oraclize
  deployer.deploy(Market1, 80000000, { from: accounts[1], value: 25000000000000000000 });
};
