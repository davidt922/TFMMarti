window.dialog = {};

//$(function(){}); is equals to $(document).ready(function(){})
$( function()
{
  var  form;

  dialog = $( "#dialog-form" ).dialog(
  {
    autoOpen: false,
    height: 400,
    width: 350,
    modal: true,
    close: function()
    {
     form[ 0 ].reset();
    }
  });

  form = dialog.find( "form" ).on( "submit",
  function(event)
  {
    event.preventDefault();
  });
    console.log("6");
});
