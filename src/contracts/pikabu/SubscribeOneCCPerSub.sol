// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.13;

import {
    ISuperToken,
    ISuperfluid,
    SuperAppBase,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

 import { ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
 import "@openzeppelin/contracts/utils/Counters.sol";

contract SubscirbeOneCCPerSub is SuperAppBase, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string constant private _name = "Subscriptions";
    string constant private _symbol = "SUB";

    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1; //initialize cfaV1 variable

    IConstantFlowAgreementV1 internal immutable _cfa;
    ISuperfluid private _host;

    mapping(address => uint256) private _tokenFromAddress;
    mapping(address => bool) private _isSubscribed;
    mapping(uint256 => address) private _tokenToCC;

    constructor(ISuperfluid host, IConstantFlowAgreementV1 cfa) ERC721(_name, _symbol) 
    {
        _host = host;
        _cfa = cfa;
        //initialize InitData struct, and set equal to cfaV1        
        cfaV1 = CFAv1Library.InitData(
        host,
        //here, we are deriving the address of the CFA using the host contract
        IConstantFlowAgreementV1(
            address(host.getAgreementClass(
                    keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
                ))
            )
        );
    }

    function subscribe(address subscriber, string memory holaString) private returns(uint256)
    {
        uint256 newTokenId = _tokenIds.current();
        _mint(subscriber, newTokenId);
        _setTokenURI(newTokenId, holaString);
        _tokenFromAddress[subscriber] = newTokenId;
        _isSubscribed[subscriber] = true;

        _tokenIds.increment();
        return newTokenId;
    }

    function afterAgreementCreated(
        ISuperToken token,
        address, //agreementClass, 
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata,
        bytes calldata ctx) external override returns (bytes memory newCtx)  
        {
            newCtx = ctx;
            (address sender, ) = abi.decode(agreementData, (address, address));
            uint256 tokenId = subscribe(sender, "Hola");
            (,int96 flowRate,,) = _cfa.getFlowByID(token, agreementId);

            ISuperfluid.Context memory decompiledContext = _host.decodeCtx(ctx);
            //userData = abi.decode(decompiledContext.userData, (address));

            address receiver = abi.decode(decompiledContext.userData, (address));
            _tokenToCC[tokenId] = receiver;
            cfaV1.createFlow(receiver, token, flowRate);
        }


    function afterAgreementTerminated(
        ISuperToken _superToken,
        address, //_agreementClass,
        bytes32, // _agreementId,
        bytes calldata  _agreementData,
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    ) external override returns (bytes memory newCtx)  
        {
            newCtx = _ctx;
            (address sender, ) = abi.decode(_agreementData, (address, address));
            uint256 tokenId = _tokenFromAddress[sender];

            _burn(tokenId);
            _isSubscribed[sender] = false;
            ISuperfluid.Context memory decompiledContext = _host.decodeCtx(_ctx);
            //userData = abi.decode(decompiledContext.userData, (address));

            address receiver = abi.decode(decompiledContext.userData, (address));
            cfaV1.deleteFlow(address(this), receiver, _superToken);

        }

        function isSubscribed(address subscriptor, address content_creator) external view returns(bool) {
            if(_isSubscribed[subscriptor]) {return false;}

            uint256 tokenId = _tokenFromAddress[subscriptor];
            if(_tokenToCC[tokenId] != content_creator) {return false;}

            return true;
        } 
}