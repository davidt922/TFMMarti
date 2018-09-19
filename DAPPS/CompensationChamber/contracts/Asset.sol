pragma solidity ^0.4.20;

contract Asset
{
    string instrumentID;
    string market;
    address owner;
    address settlementAddress;

    modifier onlySettlement
    {
       require(msg.sender == settlementAddress);
       _;
    }

    constructor(string _instrumentID, string _market) public
    {
        settlementAddress = msg.sender;
        owner = 0;
        instrumentID = _instrumentID;
        market = _market;
    }

    function changeTheOwner(address newOwner) public onlySettlement
    {
        owner = newOwner;
    }

    function getTheOwner() public view returns(address)
    {
        return owner;
    }
}
