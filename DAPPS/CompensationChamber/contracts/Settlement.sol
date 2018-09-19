pragma solidity ^0.4.20;

import "./Asset.sol";

contract Settlement
{
    mapping(string => address[]) mapInstrumentIDToAssetsContracts;

    address marketAddress;
    address compensationChamberAddress;

    /**
     * Modifiers
     */

    modifier onlyMarket
    {
        require (msg.sender == marketAddress);
        _;
    }

    constructor (address _marketAddress)
    {
        compensationChamberAddress = msg.sender;
        marketAddress = _marketAddress;
    }

    function IPO (string instrumentID, string market, uint amount) onlyMarket
    {
        for(uint i = 0; i<amount; i++)
        {
            mapInstrumentIDToAssetsContracts[instrumentID].push(new Asset(instrumentID, market));
        }
    }

    function changeTheOwnerOfAllAssetsOfContract(string InstrumentID, uint amount, address actualOwner, address futureOwner) returns(bool)
    {
        bool isChanged;

        for (uint i = 0; i < amount; i++)
        {
            isChanged = changeTheOwnerOfAnAsset(actualOwner, futureOwner, InstrumentID);

            if (isChanged == false)
            {
                return false;
            }
        }

        return true;
    }


    function changeTheOwnerOfAnAsset(address actualOwner, address futureOwner, string InstrumentID) private returns (bool)
    {
        address[] assets = mapInstrumentIDToAssetsContracts[InstrumentID];
        Asset _Asset;

        for(uint i = 0; i < assets.length; i++)
        {
            _Asset = Asset(assets[i]);

            if (_Asset.getTheOwner() == actualOwner)
            {
                _Asset.changeTheOwner(futureOwner);
                return true;
            }
        }
        return false;
    }
}
