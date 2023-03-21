// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.8;

interface INFTFactory {
    error InitializableContractAlreadyInitialized();
    error NFTFactoryNewImplementationIsZeroAddress();
    error NFTFactoryNewProxyAdminIsZeroAddress();
    error NFTFactoryInvalidBaseOperators();
    error OperatorableCallerNotAdmin();
    error OperatorableCallerNotAdminOrRelay();
    error OperatorableCallerNotAdminOrSystem();
    error OperatorableCallerNotMultisig();
    error OperatorableCallerNotOperator();
    error OperatorableCallerNotOperatorOrAdminOrRelay();
    error OperatorableCallerNotOperatorOrRelay();
    error OperatorableCallerNotOperatorOrSystem();
    error OperatorableCallerNotOperatorOrSystemOrRelay();
    error OperatorableCallerNotOperatorsContract(address _caller);
    error OperatorableCallerNotRelay();
    error OperatorableCallerNotSystem();
    error OperatorableNewOperatorsZeroAddress();

    event ImplementationChanged(address _newImplementation);
    event NewCollection(uint256 _id, address _proxyAddress);
    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);
    event ProxyAdminChanged(address _newCollectionAdmin);

    function changeImplementation(address _newImplementation) external;

    function changeProxyAdmin(address _newProxyAdmin) external;

    function confirmOperatorsContract() external;

    function deployedCollections(uint256) external view returns (address);

    function deployedCollectionsLength() external view returns (uint256);

    function getOperatorsContract() external view returns (address);

    function getOperatorsPending() external view returns (address);

    function implementation() external view returns (address);

    function initialize(
        address _impl,
        address _admin,
        address _baseOperators
    ) external;

    function isAdmin(address _account) external view returns (bool);

    function isAdminOrSystem(address _account) external view returns (bool);

    function isInitialized() external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function isOperator(address _account) external view returns (bool);

    function isOperatorOrSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function newCollection(
        string memory _name,
        string memory _symbol,
        bytes memory _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) external returns (address);

    function proxyAdmin() external view returns (address);

    function setOperatorsContract(address _baseOperators) external;
}
