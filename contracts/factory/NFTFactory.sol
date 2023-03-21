// SPDX-License-Identifier: Unlicensed

/**
 * @title NFTFactory
 * @author Team 3301 <team3301@sygnum.com>
 * @dev Factory to be used by operators to deploy arbitrary Sygnum ERC1155 contracts.
 */
pragma solidity ^0.8.8;

import "../SygnumERC1155.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@sygnum/solidity-base-contracts/contracts/helpers/Initializable.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/Operatorable.sol";

/**
 * @title NFT Factory Contract
 * @author Team 3301 <team3301@sygnum.com>
 * @dev The NFTFactory contract is used to produce new collections in the form of a proxy, linking it to
 * a specified implementation contract and initializing it with the appropriate parameters
 */
contract NFTFactory is Initializable, Operatorable {
    address public implementation;
    address public proxyAdmin;

    address[] public deployedCollections;

    event NewCollection(uint256 indexed _id, address indexed _proxyAddress);
    event ProxyAdminChanged(address indexed _newCollectionAdmin);
    event ImplementationChanged(address indexed _newImplementation);

    error NFTFactoryNewProxyAdminIsZeroAddress();
    error NFTFactoryNewProxyAdminIsSameAddress();
    error NFTFactoryNewImplementationIsZeroAddress();
    error NFTFactoryNewImplementationIsSameAddress();
    error NFTFactoryInvalidBaseOperators();

    /**
     * @dev Prevent that the implementation gets accidentally initialized by malicious users
     */
    constructor() {
        super._disableInitializers();
    }

    /**
     * @dev Function deploying a new collection proxy, initializing it with the specified parameters,
     * recording the new deployed collection locally and emitting an event
     * @param _encodedMaxTokenSupplies max token supplies encoded in bytes hex format (one byte per token)
     * @param _royaltyRecipient address defined to receive royalty payments from secondary marketplaces
     * @param _baseOperators address of the BaseOperators contract (defined in solidity-base-contracts)
     * @param _baseUri base URI directing to the IPFS token data
     * @param _startDate start date for mint. If 0, then mint is always open
     * @param _mintDuration duration of the mint. If 0, then sale is open-ended starting on _startDate
     */
    function _newCollection(
        string memory _name,
        string memory _symbol,
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        address _baseOperators,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) internal virtual returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            implementation,
            proxyAdmin,
            abi.encodeWithSignature(
                "initialize(string,string,bytes,address,address,string,uint256,uint256)",
                _name,
                _symbol,
                _encodedMaxTokenSupplies,
                _royaltyRecipient,
                _baseOperators,
                _baseUri,
                _startDate,
                _mintDuration
            )
        );

        deployedCollections.push(address(proxy));
        emit NewCollection(deployedCollections.length - 1, address(proxy));

        return address(proxy);
    }

    /**
     * @dev Function to change the proxy admin for future collections, callable only by owner
     * @param _newProxyAdmin New proxy admin address
     */
    function changeProxyAdmin(address _newProxyAdmin) external onlyOperator {
        if (_newProxyAdmin == address(0)) revert NFTFactoryNewProxyAdminIsZeroAddress();
        if (_newProxyAdmin == proxyAdmin) revert NFTFactoryNewProxyAdminIsSameAddress();
        proxyAdmin = _newProxyAdmin;

        emit ProxyAdminChanged(_newProxyAdmin);
    }

    /**
     * @dev Function to change the implementation for future collections, callable only by owner
     * @param _newImplementation New implementation address
     */
    function changeImplementation(address _newImplementation) external onlyOperator {
        if (_newImplementation == address(0)) revert NFTFactoryNewImplementationIsZeroAddress();
        if (_newImplementation == implementation) revert NFTFactoryNewImplementationIsSameAddress();
        implementation = _newImplementation;

        emit ImplementationChanged(_newImplementation);
    }

    /**
     * @dev Initializer function setting the implementation and proxy admin addresses for future collections
     * @param _impl The implementation address
     * @param _admin The proxy admin address
     */
    function initialize(
        address _impl,
        address _admin,
        address _baseOperators
    ) public virtual initializer {
        if (_baseOperators.code.length == 0) revert NFTFactoryInvalidBaseOperators();
        if (_impl == address(0)) revert NFTFactoryNewImplementationIsZeroAddress();
        if (_admin == address(0)) revert NFTFactoryNewProxyAdminIsZeroAddress();

        implementation = _impl;
        proxyAdmin = _admin;
        Operatorable.initialize(_baseOperators);

        emit ImplementationChanged(_impl);
        emit ProxyAdminChanged(_admin);
    }
}
