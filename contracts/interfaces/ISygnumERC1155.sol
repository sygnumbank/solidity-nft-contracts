// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

interface ISygnumERC1155 {
    error InitializableContractAlreadyInitialized();
    error InitializableContractIsInitializing();
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
    error PausableNotPaused();
    error PausablePaused();
    error SygnumERC1155AmountExceedsMaxSupply();
    error SygnumERC1155BatchLimitExceeded();
    error SygnumERC1155InvalidBaseOperators();
    error SygnumERC1155InvalidBaseUri();
    error SygnumERC1155InvalidMaxTokenSupplies();
    error SygnumERC1155InvalidMintDuration();
    error SygnumERC1155InvalidTokenID();
    error SygnumERC1155MintingEnded();
    error SygnumERC1155MintingNotStarted();
    error SygnumERC1155MintingZeroAmount();
    error SygnumERC1155MismatchingInputSize();
    error SygnumERC1155RoyaltyRecipientIsZeroAddress();
    error TraderOperatorableCallerNotNewTraderOperator();
    error TraderOperatorableCallerNotTrader();
    error TraderOperatorableCallerNotTraderOrOperatorOrSystem();
    error TraderOperatorableNewTraderOperatorsAddressZero();
    error TraderOperatorablePendingTraderOperatorsAddressZero();
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Initialized(uint256 _maxUniqueTokens, string _baseUri);
    event Initialized();
    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);
    event Paused(address indexed account);
    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event TraderOperatorsContractPending(address indexed caller, address indexed traderOperatorsAddress);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event URI(string value, uint256 indexed id);
    event Unpaused(address indexed account);

    function BATCH_LIMIT() external view returns (uint256);

    function balanceOf(address, uint256) external view returns (uint256);

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        external
        view
        returns (uint256[] memory balances);

    function baseUri() external view returns (string memory);

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function confirmOperatorsContract() external;

    function confirmTraderOperatorsContract() external;

    function encodedMaxTokenSupplies() external view returns (bytes memory);

    function getOperatorsContract() external view returns (address);

    function getOperatorsPending() external view returns (address);

    function getTraderOperatorsContract() external view returns (address);

    function getTraderOperatorsPending() external view returns (address);

    function initialize(
        string memory _name,
        string memory _symbol,
        bytes memory _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) external;

    function initialize(address _baseOperators, address _traderOperators) external;

    function initialize(address _baseOperators) external;

    function isAdmin(address _account) external view returns (bool);

    function isAdminOrSystem(address _account) external view returns (bool);

    function isApprovedForAll(address, address) external view returns (bool);

    function isInitialized() external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function isNotPaused() external view returns (bool);

    function isOperator(address _account) external view returns (bool);

    function isOperatorOrSystem(address _account) external view returns (bool);

    function isPaused() external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isTrader(address _account) external view returns (bool);

    function maxTokenSupply(uint256 tokenId) external view returns (uint256 res);

    function maxUniqueTokens() external view returns (uint256);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintDuration() external view returns (uint256);

    function name() external view returns (string memory);

    function pause() external;

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setOperatorsContract(address _baseOperators) external;

    function setTraderOperatorsContract(address _traderOperators) external;

    function startDate() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenSupply(uint256) external view returns (uint256);

    function unpause() external;

    function uri(uint256 tokenId) external view returns (string memory);
}
