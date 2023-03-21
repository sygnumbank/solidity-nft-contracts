// SPDX-License-Identifier: Unlicensed

/**
 * @title SygnumERC1155
 * @author Team 3301 <team3301@sygnum.com>
 * @dev Implementation of the ERC1155 standard with permissioned minting and custom supply logic.
 */
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/Initializable.sol";
import "@rari-capital/solmate/src/tokens/ERC1155.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/Pausable.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/Operatorable.sol";

/**
 * @title Sygnum implementation for the ERC1155 specification
 * @author Team 3301 <team3301@sygnum.com>
 * @dev ERC1155 implementation with max token supplies in bytes hex format, initializer for proxy support,
 * as well as support for admin and operator roles
 */
contract SygnumERC1155 is Initializable, Operatorable, Pausable, ERC1155, ERC2981 {
    using Strings for uint256;

    event Initialized(uint256 _maxUniqueTokens, string _baseUri);

    error SygnumERC1155MintingNotStarted();
    error SygnumERC1155MintingEnded();
    error SygnumERC1155AmountExceedsMaxSupply();
    error SygnumERC1155InvalidTokenID();
    error SygnumERC1155InvalidBaseOperators();
    error SygnumERC1155MintingZeroAmount();
    error SygnumERC1155RoyaltyRecipientIsZeroAddress();
    error SygnumERC1155InvalidBaseUri();
    error SygnumERC1155InvalidMaxTokenSupplies();
    error SygnumERC1155InvalidMintDuration();
    error SygnumERC1155MismatchingInputSize();
    error SygnumERC1155BatchLimitExceeded();

    string public name;
    string public symbol;

    uint256 public constant BATCH_LIMIT = 256;

    mapping(uint256 => uint256) public tokenSupply;
    string public baseUri;

    // Launch date and minting period
    uint256 public startDate;
    uint256 public mintDuration;

    // Max amount of unique tokens
    uint256 public maxUniqueTokens;
    // Max amount of copies per token
    bytes public encodedMaxTokenSupplies;

    /**
     * @dev Modifier checking whether minting is open. If startDate is 0, then minting is always open.
     * If startDate is not 0, then minting is open between startDate and startDate + mintDuration.
     */
    modifier isMintOpen() {
        if (startDate > 0) {
            if (block.timestamp < startDate) revert SygnumERC1155MintingNotStarted();
            if (mintDuration > 0) {
                if (block.timestamp >= startDate + mintDuration) revert SygnumERC1155MintingEnded();
            }
        }
        _;
    }

    /**
     * @dev Prevent that the implementation gets accidentally initialized by malicious users
     */
    constructor() {
        super._disableInitializers();
    }

    /**
     * @dev Function returning the maximum supply for a specific token ID, decoding it from the bytes hex format
     * @param tokenId The token ID
     * @return res The maximum supply for tokenId
     */
    function maxTokenSupply(uint256 tokenId) public view virtual returns (uint256 res) {
        res = uint16(
            bytes2(abi.encodePacked(encodedMaxTokenSupplies[2 * tokenId], encodedMaxTokenSupplies[2 * tokenId + 1]))
        );
    }

    /**
     * @dev Implements the safeTransferFrom function while checking whether the contract is paused
     * @param from Sender account
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to send
     * @param data Calldata to pass if recipient is contract
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        ERC1155.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Implements the safeBatchTransferFrom function while checking whether the contract is paused
     * @param from Sender account
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to send for each token
     * @param data Calldata to pass if recipient is contract
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        if (ids.length > BATCH_LIMIT) {
            revert SygnumERC1155BatchLimitExceeded();
        }
        ERC1155.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Minting function which limits calls to operator accounts only
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to mint
     * @param data Calldata to pass if recipient is contract
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual onlyOperator {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Batch minting function which limits calls to operator accounts only
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to mint for each token
     * @param data Calldata to pass if recipient is contract
     */
    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external virtual onlyOperator {
        _batchMint(to, ids, amounts, data);
    }

    /**
     * @dev Internal minting function which limits minting to specified period (if startDate is 0, then mint is
     * always open, if mintDuration is 0 then sale is open-ended). Also checks whether token ID is valid and
     * whether minting exceeds max token supply
     * @param to Recipient account
     * @param id Token ID
     * @param amount Amount of tokens to mint
     * @param data Calldata to pass if recipient is contract
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override isMintOpen {
        if (amount == 0) revert SygnumERC1155MintingZeroAmount();

        if (id >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();
        if (tokenSupply[id] + amount > maxTokenSupply(id)) revert SygnumERC1155AmountExceedsMaxSupply();

        tokenSupply[id] += amount;
        ERC1155._mint(to, id, amount, data);
    }

    /**
     * @dev Internal batch minting function which limits minting to specified period (if startDate is 0, then mint
     * is always open, if mintDuration is 0 then sale is open-ended). Also checks whether token IDs are valid and
     * whether minting exceeds max token supply for each token
     * @param to Recipient account
     * @param ids Array of token IDs
     * @param amounts Array of amounts to mint for each token
     * @param data Calldata to pass if recipient is contract
     */
    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override isMintOpen {
        if (ids.length > BATCH_LIMIT) {
            revert SygnumERC1155BatchLimitExceeded();
        }

        if (ids.length != amounts.length) revert SygnumERC1155MismatchingInputSize();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (id >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();
            if (tokenSupply[id] + amount > maxTokenSupply(id)) revert SygnumERC1155AmountExceedsMaxSupply();

            tokenSupply[id] += amount;
        }

        ERC1155._batchMint(to, ids, amounts, data);
    }

    /**
     * @dev Initializer for proxy use
     * @param _encodedMaxTokenSupplies max token supplies encoded in bytes hex format (two bytes per token)
     * @param _royaltyRecipient address defined to receive royalty payments from secondary marketplaces
     * @param _baseOperators address of the BaseOperators contract (defined in solidity-base-contracts)
     * @param _baseUri base URI directing to the IPFS token data
     * @param _startDate start date for mint. If 0, then mint is always open
     * @param _mintDuration duration of the mint. If 0, then sale is open-ended starting on _startDate
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) public initializer {
        if (_baseOperators.code.length == 0) revert SygnumERC1155InvalidBaseOperators();
        if (_royaltyRecipient == address(0)) revert SygnumERC1155RoyaltyRecipientIsZeroAddress();
        if (bytes(_baseUri).length == 0) revert SygnumERC1155InvalidBaseUri();
        if (_encodedMaxTokenSupplies.length % 2 != 0) revert SygnumERC1155InvalidMaxTokenSupplies();
        if (_startDate == 0 && _mintDuration > 0) revert SygnumERC1155InvalidMintDuration();

        if (_startDate > 0 && _mintDuration > 0) {
            if (_startDate + _mintDuration < block.timestamp) revert SygnumERC1155InvalidMintDuration();
        }

        name = _name;
        symbol = _symbol;

        encodedMaxTokenSupplies = _encodedMaxTokenSupplies;
        maxUniqueTokens = _encodedMaxTokenSupplies.length / 2;

        baseUri = _baseUri;

        startDate = _startDate;
        mintDuration = _mintDuration;

        ERC2981._setDefaultRoyalty(_royaltyRecipient, 0);
        Operatorable.initialize(_baseOperators);
        emit Initialized(_encodedMaxTokenSupplies.length, _baseUri);
    }

    /**
     * @dev Function returning the URI to access token metadata
     * @param tokenId The token ID
     * @return string The corresponding URI in string format
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId >= maxUniqueTokens) revert SygnumERC1155InvalidTokenID();

        string memory baseURI = baseUri;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /**
     * @dev Mandatory override. See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return ERC2981.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId);
    }

    /**
     * @dev Public restricted function to change the default royalty rate.
     * @param receiver The address receiving royalty payments
     * @param feeNumerator The fee rate expressed in basis points (per 10k)
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external virtual onlyOperator {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
