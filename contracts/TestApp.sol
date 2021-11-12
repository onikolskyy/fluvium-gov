import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    ISuperAgreement,
    SuperAppDefinitions
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {
    IConstantFlowAgreementV1
} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";


import {
    SuperAppBase
} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library GovFlowLogic {

    function modifyOutFlow(
        ISuperfluid _host,
        IConstantFlowAgreementV1 _cfa,
        ISuperToken _acceptedToken,
        address objective,
        int96 flowRate,
        int96 newOutFlow
    )
    internal
    {
        if(newOutFlow <= 0 && flowRate > 0){
            // close stream to objective
            _host.callAgreement(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.deleteFlow.selector,
                    _acceptedToken,
                    address(this),
                    objective,
                    new bytes(0)
                ), // call data
                new bytes(0) // user data
            );
        } else {
            if(flowRate > 0){
                _host.callAgreement(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.updateFlow.selector,
                        _acceptedToken,
                        objective,
                        newOutFlow,
                        new bytes(0)
                    ), // call data
                    new bytes(0) // user data
                );
            } else {
                // open new stream to objective
                _host.callAgreement(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.createFlow.selector,
                        _acceptedToken,
                        objective,
                        newOutFlow,
                        new bytes(0)
                    ), // call data
                    new bytes(0) // user data
                );
            }
        }
    }

    function modifyOutFlowWithContext(
        ISuperfluid _host,
        IConstantFlowAgreementV1 _cfa,
        ISuperToken _acceptedToken,
        address objective,
        int96 flowRate,
        int96 newOutFlow,
        bytes memory ctx
    )
    internal returns (bytes memory newCtx){
         if(newOutFlow <= 0 && flowRate > 0){
            // close stream to objective
             (newCtx,) = _host.callAgreementWithContext(
                _cfa,
                abi.encodeWithSelector(
                    _cfa.deleteFlow.selector,
                    _acceptedToken,
                    address(this),
                    objective,
                    new bytes(0)
                ), // call data
                new bytes(0), // user data
                ctx
            );
        } else {
            if( flowRate > 0){
                (newCtx,) = _host.callAgreementWithContext(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.updateFlow.selector,
                        _acceptedToken,
                        objective,
                        newOutFlow,
                        new bytes(0)
                    ), // call data
                    new bytes(0), // user data
                    ctx
                );
            } else {
                // open new stream to objective
                (newCtx,) = _host.callAgreementWithContext(
                    _cfa,
                    abi.encodeWithSelector(
                        _cfa.createFlow.selector,
                        _acceptedToken,
                        objective,
                        newOutFlow,
                        new bytes(0)
                    ), // call data
                    new bytes(0), // user data
                    ctx
                );
            }
        }
    }

}

contract TestApp is SuperAppBase, ERC721, Ownable {

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token

    int96 VOTE_AMOUNT = 100; // Every voter has 100 votes

    int96 private _flowRateIn;

    address[] private _objectivesArray;  // save objectives here
    mapping(uint256 => mapping(address => int96)) _votes;    // opinion per voter per objective
    mapping(address => int96) _totalVotes;
    mapping(bytes32 => int96) _inFlowRates;
    mapping(uint256 => int96) _totalVotesUsed;

    int96 private _totalSupply; // TODO: it shoul be uint256

    uint256 public nextId; // this is so we can increment the number (each stream has new id we store in flowRates)

    constructor(
        string memory _name,
        string memory _symbol,
        address owner,
        ISuperfluid host,
        IConstantFlowAgreementV1 cfa,
        ISuperToken acceptedToken
    )
    ERC721(_name,_symbol)
    {
        assert(address(host) != address(0));
        assert(address(cfa) != address(0));
        assert(address(acceptedToken) != address(0));

        _host = host;
        _cfa = cfa;
        _acceptedToken = acceptedToken;
        _flowRateIn = 0;

        uint256 configWord =
            SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            //SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP ;
            //SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);

        _totalSupply = 0;
        nextId = 0;
    }


    /**************************************************************************
     * GovFlow Logic
     *************************************************************************/

    function makeProposal(address objective)
    external
    onlyOwner
    {
        _objectivesArray.push(objective);
    }


    function revokeProposal(address objective)
    external
    onlyOwner
    {
        // TODO: implement
    }


    function reVote(uint256 tokenId, address objective, int96 newVote)
    external //returns (int96)
    {
        require(msg.sender==ownerOf(tokenId), "Only NFT owners can vote");
        require(newVote >= 0, "can't be negative");

        require(_totalVotesUsed[tokenId] - _votes[tokenId][objective] + newVote <= 100, "a voter has 100 votes");
        (, int96 flowRate,,) = _cfa.getFlow(_acceptedToken,address(this), objective);
        _totalVotes[objective] = _totalVotes[objective] - _votes[tokenId][objective] + newVote;
        _votes[tokenId][objective] = newVote;
        GovFlowLogic.modifyOutFlow(_host, _cfa, _acceptedToken, objective, flowRate, _flowRateIn *  _totalVotes[objective] / (VOTE_AMOUNT * _totalSupply));
    }

    // scale all outgoing flows if incoming flow change
    function _updateOutFlowFromCB(bytes memory ctx)
    private returns (bytes memory newCtx)
    {
        newCtx = ctx;
        for(uint i=0; i < _objectivesArray.length;i++)
        {
            if(_totalVotes[_objectivesArray[i]] > 0){
                (, int96 flowRate,,) = _cfa.getFlow(_acceptedToken,address(this), _objectivesArray[i]);
                newCtx = GovFlowLogic.modifyOutFlowWithContext(
                    _host, _cfa, _acceptedToken,
                    _objectivesArray[i], flowRate,
                    _flowRateIn *  _totalVotes[_objectivesArray[i]] / (VOTE_AMOUNT * _totalSupply),
                    newCtx
                );
            }
        }

        return newCtx;
    }


    /////////////////////////////////////////////////////
    //
    // NFT logic
    //
    ////////////////////////////////////////////////////

    event NFTIssued(uint256 tokenId);

    function issueNFT(address receiver) external onlyOwner{
        _issueNFT(receiver);
    }

    function _issueNFT(address receiver) internal{
        require(receiver != address(this), "Issue to a new address");
        _mint(receiver, nextId);

        emit NFTIssued(nextId);

        nextId += 1;
        _totalSupply = _totalSupply + 1;
    }



    /////////////////////////////////////////////////////
    //
    // Super App
    //
    ////////////////////////////////////////////////////


    function afterAgreementCreated(
        ISuperToken _superToken,
        address /*_agreementClass*/,
        bytes32 agreementId,
        bytes calldata /*_agreementData*/,
        bytes calldata /*_cbdata*/,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory newCtx)
    {
        (,int96 flowRate,,) = _cfa.getFlowByID(_acceptedToken, agreementId);
        _flowRateIn = _flowRateIn + flowRate;
        _inFlowRates[agreementId] = flowRate;
        return _updateOutFlowFromCB(ctx);
    }


     function afterAgreementUpdated(
        ISuperToken /* superToken */,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata /*agreementData*/,
        bytes calldata ,// cbdata,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory)
    {
         (,int96 flowRate,,) = _cfa.getFlowByID(_acceptedToken, agreementId);
        _flowRateIn = _flowRateIn - _inFlowRates[agreementId] + flowRate;
        return _updateOutFlowFromCB(ctx);
    }



    function afterAgreementTerminated(
        ISuperToken /* superToken */,
        address /* agreementClass */,
        bytes32 agreementId ,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external override
        onlyHost
        returns (bytes memory )
    {
         (,int96 flowRate,,) = _cfa.getFlowByID(_acceptedToken, agreementId);
        _flowRateIn = _flowRateIn - flowRate;
        return _updateOutFlowFromCB(ctx);
    }

    modifier onlyHost() {
        require(msg.sender == address(_host), "Process SuperApp: supports only one host");
        _;
    }

}