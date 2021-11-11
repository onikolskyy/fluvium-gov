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

contract TestApp is SuperAppBase, ERC721 {

    ISuperfluid private _host; // host
    IConstantFlowAgreementV1 private _cfa; // the stored constant flow agreement class address
    ISuperToken private _acceptedToken; // accepted token

    int96 VOTE_AMOUNT = 100; // Every voter has 100 votes

    int96 private _flowRateIn;

    address[] private _objectivesArray;  // save objectives here
    mapping(address => mapping(address => int96)) _voteAmounts;    // opinion per voter per objective
    mapping(address => int96) _totalOpinions;

    uint16 MAX_VOTERS;

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
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP |
            SuperAppDefinitions.AFTER_AGREEMENT_TERMINATED_NOOP;

        _host.registerApp(configWord);
    }


    /**************************************************************************
     * GovFlow Logic
     *************************************************************************/

    function addObjective(address objective)
    public
    {
        _objectivesArray.push(objective);
    }

    event reVoteTest(int96 flowRateIn, int96 flowRateOut);


    function reVote(address objective, int96 newVote)
    external //returns (int96)
    {
        (, int96 flowRate,,) = _cfa.getFlow(_acceptedToken,address(this), objective);
        _totalOpinions[objective] = _totalOpinions[objective] - _voteAmounts[msg.sender][objective] + newVote;
        _voteAmounts[msg.sender][objective] = newVote;
        GovFlowLogic.modifyOutFlow(_host, _cfa, _acceptedToken, objective, flowRate, _flowRateIn *  _totalOpinions[objective] / (VOTE_AMOUNT));
    }

    // scale all outgoing flows if incoming flow change
    function _updateOutFlowFromCB(bytes memory ctx)
    private returns (bytes memory newCtx)
    {
        newCtx = ctx;
        for(uint i=0; i < _objectivesArray.length;i++)
        {
            (, int96 flowRate,,) = _cfa.getFlow(_acceptedToken,address(this), _objectivesArray[i]);
            if(_totalOpinions[_objectivesArray[i]] > 0){
                newCtx = GovFlowLogic.modifyOutFlowWithContext(
                    _host, _cfa, _acceptedToken,
                    _objectivesArray[i], flowRate,
                    _flowRateIn *  _totalOpinions[_objectivesArray[i]] / (VOTE_AMOUNT),
                    newCtx
                );
            }
        }

        return newCtx;
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
        returns (bytes memory newCtx)
    {
        return _updateOutFlowFromCB(ctx);
    }


    modifier onlyHost() {
        require(msg.sender == address(_host), "Process SuperApp: supports only one host");
        _;
    }

}