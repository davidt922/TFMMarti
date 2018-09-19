window.showLogin = function()
{
  $('.register-form').hide();
  $('.login-form').show();
}

window.showRegister = function()
{
  $('.register-form').show();
  $('.login-form').hide();
}


$(document).ready(function ()
{
  showLogin();
  $('#register').click(function ()
  {
    showLogin();
  });
  $('#login').click(function ()
  {
    showRegister();
  });

  $('#account').click(function()
  {
    openAccountDialog();
  });
});

window.addEventListener('load', function()
{
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined')
  {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  }
  else
  {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:8545"));
  }

  App.start();

  document.getElementById("create").addEventListener("click", function()
  {
    var name = document.getElementById("name1").value;
    var email = document.getElementById("email1").value;
    var password = document.getElementById("password1").value;
    App.addCompensationMember(name, email, password);
  }, false);

  document.getElementById("loginButton").addEventListener("click", function()
  {
    var email = document.getElementById("email2").value;
    var password = document.getElementById("password2").value;
    console.log("3");
     App.login(email, password);
  });
});
