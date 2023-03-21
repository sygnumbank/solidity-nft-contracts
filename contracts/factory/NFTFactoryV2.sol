// SPDX-License-Identifier: Unlicensed

/**
 * @title NFTFactoryV2
 * @author Team 3301 <team3301@sygnum.com>
 * @dev Factory to be used by operators to deploy arbitrary Sygnum ERC1155 contracts.
 */
pragma solidity ^0.8.8;

import "./NFTFactory.sol";

contract NFTFactoryV2 is NFTFactory {
    bool public initializedV2;
    address public collectionBaseOperators;

    error NFTFactoryV2AlreadyInitialized();

    function newCollection(
        string memory _name,
        string memory _symbol,
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri,
        uint256 _startDate,
        uint256 _mintDuration
    ) public virtual onlyOperator returns (address) {
        return
            NFTFactory._newCollection(
                _name,
                _symbol,
                _encodedMaxTokenSupplies,
                _royaltyRecipient,
                collectionBaseOperators,
                _baseUri,
                _startDate,
                _mintDuration
            );
    }

    function getDeployedCollections() public view virtual returns (address[] memory) {
        return deployedCollections;
    }

    function setCollectionBaseOperators(address _newCollectionBaseOperators) external virtual onlyAdmin {
        collectionBaseOperators = _newCollectionBaseOperators;
    }

    function initializeV2(address _collectionBaseOperators) public virtual {
        if (initializedV2) revert NFTFactoryV2AlreadyInitialized();
        collectionBaseOperators = _collectionBaseOperators;
        initializedV2 = true;
    }

    function initialize(
        address _impl,
        address _admin,
        address _baseOperators,
        address _collectionBaseOperators
    ) public initializer {
        super.initialize(_impl, _admin, _baseOperators);
        initializeV2(_collectionBaseOperators);
    }
}
