// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IProject.sol";
import "../libraries/BytesLib.sol";
import "hardhat/console.sol";

contract ProjectV1 is IProject{
    using BytesLib for bytes;
    
    enum Status {PENDING, AUDIT, VOTING, LAUNCHED}
    enum Size {SMALL, MEDIUM, LARGE}
    enum Type {PREPRODCAPITAL, PREREVCAPITAL, POSTREVCAPITAL, LIQUIDITY, INDIVASSET}
    enum TokenRestriction {R506B, R506C, RSEC4A2, R504, REGA, ADVSET}

    bytes32 public id;
    bytes public name;
    bytes public description;
    bytes public documentFolderURI;
    Status public status;
    Size public size;
    uint public override launchDate;
    uint public override offeringEndDate;
    Type public projectType;
    bytes32 public country;
    bytes32 public city;
    uint public override maxSupply;
    uint public maxTokenOffering;
    uint public override tokenPrice;
    uint public minCap;
    uint public maxCap;
    uint public goal;
    TokenRestriction public tokenRestriction;
    bytes32 creatorId;
    uint public estimatedValuation;
    uint public completionEndDate;

    constructor(bytes32 _projectId, bytes memory _dataString) {
        id = _projectId;
        parseDataString(_dataString);
    }

    function updateProjectData(bytes32 _projectId, bytes memory _dataString) external override {
        require(id == _projectId, 'Invalid project Id');
        parseDataString(_dataString);
    }

    function getDataString() external view override returns(bytes memory _dataString) {
        _dataString = _dataString.concat(abi.encodePacked(id));

        _dataString = _dataString.concat(abi.encodePacked(uint16(name.length)));
        _dataString = _dataString.concat(name);

        _dataString = _dataString.concat(abi.encodePacked(uint16(description.length)));
        _dataString = _dataString.concat(description);

        _dataString = _dataString.concat(abi.encodePacked(uint16(documentFolderURI.length)));
        _dataString = _dataString.concat(documentFolderURI);

        _dataString = _dataString.concat(abi.encodePacked(uint16(1)));
        _dataString = _dataString.concat(abi.encodePacked(status));

        _dataString = _dataString.concat(abi.encodePacked(uint16(1)));
        _dataString = _dataString.concat(abi.encodePacked(size));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(launchDate));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(offeringEndDate));

        _dataString = _dataString.concat(abi.encodePacked(uint16(1)));
        _dataString = _dataString.concat(abi.encodePacked(projectType));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(country));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(city));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(maxSupply));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(maxTokenOffering));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(tokenPrice));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(minCap));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(maxCap));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(goal));

        _dataString = _dataString.concat(abi.encodePacked(uint16(1)));
        _dataString = _dataString.concat(abi.encodePacked(tokenRestriction));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(creatorId));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(estimatedValuation));

        _dataString = _dataString.concat(abi.encodePacked(uint16(32)));
        _dataString = _dataString.concat(abi.encodePacked(completionEndDate));
    }

    function parseDataString(bytes memory _dataString) internal {
        uint si = 0;
        uint segLen;
        //Extract Id
        id = _dataString.slice(si, 32).toBytes32(0);
        si += 32;
        
        if(si >= _dataString.length) {
            return;
        }

        //Extract name
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        name =_dataString.slice(si, segLen);
        si += segLen;
        if(si >= _dataString.length) {
            return;
        }

        //Extract description
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        description =_dataString.slice(si, segLen);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract documentFolderURI
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        documentFolderURI =_dataString.slice(si, segLen);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract status
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        status = Status(_dataString.slice(si, segLen).toUint8());
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract size
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        size = Size(_dataString.slice(si, segLen).toUint8());
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract launchDate
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        launchDate =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract offeringEndDate
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        offeringEndDate =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract projectType
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        projectType = Type(_dataString.slice(si, segLen).toUint8());
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract country
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        country =_dataString.slice(si, segLen).toBytes32(0);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract city
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        city =_dataString.slice(si, segLen).toBytes32(0);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract maxSupply
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        maxSupply =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract maxTokenOffering
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        maxTokenOffering =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract tokenPrice
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        tokenPrice =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract minCap
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        minCap =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract maxCap
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        maxCap =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract goal
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        goal =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract tokenRestriction
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        tokenRestriction = TokenRestriction(_dataString.slice(si, segLen).toUint8());
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract creatorId
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        creatorId =_dataString.slice(si, segLen).toBytes32(0);
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract estimatedValuation
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        estimatedValuation =_dataString.slice(si, segLen).toUint();
        si += segLen;

        if(si >= _dataString.length) {
            return;
        }

        //Extract completionEndDate
        segLen = _dataString.slice(si, 2).toUint16();
        si += 2;
        completionEndDate =_dataString.slice(si, segLen).toUint();
        si += segLen;
    }
}