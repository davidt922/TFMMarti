pragma solidity ^0.4.20;

//import "installed_contracts/oraclize-api/contracts/usingOraclize.sol";
import "./usingOraclize.sol";
import "./strings.sol";


library Utils
{
  using strings for *;

    struct order
    {
        address clearingMemberAddress;
        uint16 quantity;
        uint timestamp;
        uint16 price; // the las 3 numbers of the integer represents the decimals, so 3000 equals to 3.
    }
    struct marketOrder
    {
      uint16 quantity;
      uint16 price;
    }

    enum instrumentType
    {
        future,
        swap
    }

    enum paymentType
    {
        initialMargin,
        variationMargin
    }

    enum side
    {
      buy,
      sell
    }

    enum orderType
    {
      add,
      remove
    }


    enum market
    {
      BOE,
      EUREX,
      CME
    }
    struct variationMarginChange
    {
        address clearingMemberAddress;
        int value;
    }

    struct clearingMember
    {
      bytes32 name;
      bytes32 email;
      address clearingMemberAddress;
      bytes32 password;
      int16 addressID;
    }

    // Convert from bytes32 to String
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string)
    {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++)
        {
        bytesArray[i] = _bytes32[i];
        }

        var stringToParse = string(bytesArray).toSlice();
        strings.slice memory part;

        // remove all \u0000 after the word
        stringToParse.split("\u0000".toSlice(), part);
        return part.toString();
    }

    // Convert addressToString
    function addressToString(address x) internal pure returns (string)
    {
        bytes memory b = new bytes(20);

        for (uint i = 0; i < 20; i++)
        {
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        }
        return string(b);
    }

    // Convert string to bytes32
    function stringToBytes32(string memory source) internal pure returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0)
        {
            return 0x0;
        }
        assembly
        {
            result := mload(add(source, 32))
        }
    }

    // Convert string of type 0.125 to int, the first value will be 0 for positive and 1 for negative, so 0.125 = 125 and 1.125 = -125
    function stringToInt(string s) internal pure returns (int)
    {
      var sliceVal = s.toSlice();
      strings.slice memory part;
      var num = sliceVal.split(".".toSlice(), part);
      string memory numString = num.toString();
      var numVal = sliceVal.split(".".toSlice(), part);
      uint result = stringToUint(numVal.toString());
      int resultInt = int(result);
      if (compareStrings(numString, "0"))
      {
          return resultInt;
      }
      else
      {
       return resultInt * -1;
      }
    }
    // Convert string to Uint
    function stringToUint(string s) internal pure returns (uint result)
    {
        bytes memory b = bytes(s);
        uint i;
        result = 0;

        for (i = 0; i < b.length; i++)
        {
            uint c = uint(b[i]);

            if (c >= 48 && c <= 57)
            {
                result = result * 10 + (c - 48);
            }
        }
    }

    // convert string of type: [aa, cc] to an array of bytes32 ["aa", "cc"]
    function stringToBytes32Array2(string result) internal pure returns (bytes32[2] memory)
    {
        var stringToParse = result.toSlice();
        stringToParse.beyond("[".toSlice()).until("]".toSlice()); //remove [ and ]
        var delim = ",".toSlice();
        bytes32[2] memory parts;

        for (uint i = 0; i < parts.length; i++)
        {
            parts[i] = stringToBytes32(stringToParse.split(delim).toString());
        }

        return parts;
    }

    // Convert string of type: [aa, cc] to an array of uint ["aa", "cc"]
    function stringToUintArray2(string result) internal pure returns (uint[2] memory)
    {
        var stringToParse = result.toSlice();
        //stringToParse.beyond("[".toSlice()).until("]".toSlice()); //remove [ and ]
        var delim = " ".toSlice();
        uint[2] memory parts;

        for (uint i = 0; i < parts.length; i++)
        {
            parts[i] = stringToUint(stringToParse.split(delim).toString());
        }
        return parts;
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string)
    {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string)
    {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function removeUint(uint[] array, uint index)  internal pure returns(uint[])
    {
        if (index >= array.length) return;

        for (uint i = index; i<array.length-1; i++)
        {
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        return array;
    }

    function removeAddress(address[] array, uint index) internal pure returns(address[])
    {
        if (index >= array.length) return;

        for (uint i = index; i<array.length-1; i++)
        {
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        return array;
    }

    function compareStrings (string a, string b) internal pure returns (bool)
    {
        return keccak256(a) == keccak256(b);
    }

    // Convert Uint to bytes32
  /*  function uintToBytes(uint v) internal pure returns (bytes32 ret)
    {
        if (v == 0)
        {
            ret = '0';
        }
        else
        {
            while (v > 0)
            {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }*/
    // Convert Uint to bytes32
    function uint16ToBytes(uint16 v) internal pure returns (bytes32 ret)
    {
        if (v == 0)
        {
            ret = '0';
        }
        else
        {
            while (v > 0)
            {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }
        // Convert Uint to bytes32
    function uintToBytes(uint v) internal pure returns (bytes32 ret)
    {
        if (v == 0)
        {
            ret = '0';
        }
        else
        {
            while (v > 0)
            {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    // convert 123332 to 123.321
    function uint16PriceToBytes32(uint16 price) internal pure returns(bytes32)
    {
        uint16 _int = uint16(price/1000);
        uint16 _v = _int * 1000;
        uint16 _dec = price - _v;

        bytes32 _intBytes32 = uint16ToBytes(_int);
        bytes32 _decBytes32 = uint16ToBytes(_dec);
        string memory _intString = bytes32ToString(_intBytes32);
        string memory _decString = bytes32ToString(_decBytes32);

        return stringToBytes32(strConcat(_intString,".",_decString));
    }

    function uintToString(uint value) internal pure returns(string)
    {
        bytes32 _value = uintToBytes(value);
        string memory _valueString = bytes32ToString(_value);

        return _valueString;
    }


    function removeOrder(order[] storage array, uint index) internal
    {
        if (index >= array.length) return;

        for (uint i = index; i<array.length-1; i++)
        {
            array[i] = array[i+1];
        }
        delete array[array.length-1];
        array.length--;
    }

}
