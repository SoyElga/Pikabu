// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.13;

import { RedirectAll } from "../superfluid/tradable-cashflow/RedirectAll.sol";

import { IConstantFlowAgreementV1,
ISuperToken,
ISuperfluid,
SuperAppBase,
SuperAppDefinitions,
StreamInDistributeOut
} from "../superfluid/stream-in-distribute-out/StreamInDistributeOut.sol";

 import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
 import "@openzeppelin/contracts/utils/Counters.sol";

contract SubscirbeOneCCPerSub is SuperAppBase, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping();
    constructor() ERC721("Subscription","SUB") {}

    function subscribe(address subscriber, string memory _tokenURI) private returns(uint256)
    {
        uint256 newTokenId = _tokenIds.current();
        _mint(subscriber, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        _tokenIds.increment();
        return newTokenId;
    }

    function afterAgreementCreated(
        ISuperToken token,
        address agreementClass, 
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata,
        bytes calldata ctx) external override returns (bytes memory newCtx)  
        {
            (address sender, ) = abi.decode(agreementData, (address, address));
            (,int96 flowRate,,) = _cfa.getFlowByID(token, agreementId);

            address receiver = "Content Creator"
            cfaV1.createFlow(receiver, token, flowRate);
        }

/*
    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, // _agreementData
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    ) external override(RedirectAll, StreamInDistributeOut) onlyHost returns (bytes memory newCtx)  
        {

        }
*/
}