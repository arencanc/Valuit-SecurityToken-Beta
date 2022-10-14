// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC1400.sol";
import "../libraries/BytesLib.sol";
import "../tokens/SecurityTokenProxyV1.sol";

contract STFactoryFacet {
    using BytesLib for bytes;

    function createSecurityTokenContract(bytes32 _contractVersion, address _projectAddress, address _contractCreator, bytes memory _dataString) external returns(address _contract) {
        if(_contractVersion == "V1") {
            (string memory name, string memory symbol, uint8 decimal, uint8 granularity, address[] memory controllers, bytes32[] memory defaultPartitions) 
                    = parseData(_dataString);
            _contract = address(new SecurityTokenProxyV1(_projectAddress, _contractCreator, name, symbol, decimal, granularity, controllers, defaultPartitions));
        }
        // else if(_contractVersion == "V2") {
        //    _contract = address(new SecurityTokenV2(_projectAddress, _dataString));
        // }
        else {
            require( 1==2, 'Version not supported');
        }
    }

    function parseData(bytes memory _dataString) internal pure returns(string memory name,
                                                                        string memory symbol,
                                                                        uint8 decimal,
                                                                        uint8 granularity,
                                                                        address[] memory controllers,
                                                                        bytes32[] memory defaultPartitions) {
        
        uint si = 0;
        uint segLen;

        //Extract Name
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        name =_dataString.slice(si, segLen).toString();
        si += segLen;

        if(si >= _dataString.length) {
            require( 1==2, 'Incomplete Data String');
        }

        //Extract symbol
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        symbol =_dataString.slice(si, segLen).toString();
        si += segLen;

        if(si >= _dataString.length) {
            require( 1==2, 'Incomplete Data String');
        }

        //Extract decimal
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        decimal =_dataString.slice(si, segLen).toUint8();
        si += segLen;

        if(si >= _dataString.length) {
            require( 1==2, 'Incomplete Data String');
        }

        //Extract granularity
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        granularity =_dataString.slice(si, segLen).toUint8();
        si += segLen;

        if(si >= _dataString.length) {
            require( 1==2, 'Incomplete Data String');
        }

        //Extract controllers
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        controllers = extractControllers(_dataString.slice(si, segLen));
        si += segLen;

        if(si >= _dataString.length) {
            require( 1==2, 'Incomplete Data String');
        }

        //Extract defaultPartitions
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        defaultPartitions = extractDefaultPartitions(_dataString.slice(si, segLen));
        si += segLen;
    }

    function extractControllers(bytes memory _data) internal pure returns(address[] memory _controllers) {
        require(_data.length >= 0, 'Data empty');
        uint numOfRecords = _data.length / 20;
        _controllers = new address[](numOfRecords);
        for(uint i = 0; i < numOfRecords; i++) {
            _controllers[i] = _data.slice(i * 20, 20).toAddress();
        }
    }

    function extractDefaultPartitions(bytes memory _data) internal pure returns(bytes32[] memory _defaultPartitions) {
        require(_data.length >= 0, 'Data empty');
        uint numOfRecords = _data.length / 32;
        _defaultPartitions = new bytes32[](numOfRecords);
        for(uint i = 0; i < numOfRecords; i++) {
            _defaultPartitions[i] = _data.slice(i * 32, 32).toBytes32(0);
        }
    }
}