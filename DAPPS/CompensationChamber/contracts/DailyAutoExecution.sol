pragma solidity ^0.4.24;

contract DailyAutoExecution
{
	address owner;
	constructor()
	{
		owner = msg.sender;
	}

}
