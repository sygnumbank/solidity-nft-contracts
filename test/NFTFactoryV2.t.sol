// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import "../contracts/SygnumERC1155.sol";
import "../contracts/factory/NFTFactoryV1.sol";
import "../contracts/factory/NFTFactoryV2.sol";
import "../contracts/NFTFactoryProxy.sol";

import "../contracts/interfaces/ISygnumERC1155.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/BaseOperators.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTFactoryHelper {
    NFTFactoryV1 factory;
    NFTFactoryV2 factoryV2;
    NFTFactoryProxy factoryProxy;
    NFTFactoryV1 factoryImplementation;
    NFTFactoryV2 factoryImplementationV2;
    SygnumERC1155 implementation;
    BaseOperators baseOperators;
    BaseOperators collectionBaseOperators;
    address proxyAdmin = address(1);
    address admin = address(2);
    address operator = address(3);

    string name = "SygnumERC1155";
    string symbol = "SYG1155";
    uint256 maxUniqueTokens;
    bytes encodedMaxTokenSupplies;
    string uri;

    event NewCollection(uint256 indexed _id, address indexed _proxyAddress);
    event ProxyAdminChanged(address indexed _newProxyAdmin);
    event ImplementationChanged(address indexed _newImplementation);
}

contract NFTFactorySequentialUpgrade is NFTFactoryHelper, Test {
    function setUp() public {
        implementation = new SygnumERC1155();
        factoryImplementation = new NFTFactoryV1();
        factoryImplementationV2 = new NFTFactoryV2();
        factoryProxy = new NFTFactoryProxy(address(factoryImplementation), proxyAdmin, "");
        factory = NFTFactoryV1(address(factoryProxy));
        baseOperators = new BaseOperators(admin);
        collectionBaseOperators = new BaseOperators(admin);

        vm.prank(admin);
        baseOperators.addOperator(operator);

        factory.initialize(address(implementation), proxyAdmin, address(baseOperators));
        vm.prank(proxyAdmin);
        factoryProxy.upgradeTo(address(factoryImplementationV2));

        factoryV2 = NFTFactoryV2(address(factoryProxy));
    }

    function testImplementationSetCorrectly() public {
        vm.prank(proxyAdmin);
        assertEq(factoryProxy.implementation(), address(factoryImplementationV2));
    }

    function testInitializeV2() public {
        factoryV2.initializeV2(address(collectionBaseOperators));

        assertEq(factoryV2.initializedV2(), true);
        assertEq(factoryV2.collectionBaseOperators(), address(collectionBaseOperators));
    }

    function testCannotReinitializeV2() public {
        factoryV2.initializeV2(address(collectionBaseOperators));

        vm.expectRevert(abi.encodeWithSignature("NFTFactoryV2AlreadyInitialized()"));
        factoryV2.initializeV2(address(collectionBaseOperators));
    }

    function testCannotCallMainInitialize() public {
        factoryV2.initializeV2(address(collectionBaseOperators));

        vm.expectRevert(abi.encodeWithSignature("InitializableContractAlreadyInitialized()"));
        factoryV2.initialize(
            address(implementation),
            proxyAdmin,
            address(baseOperators),
            address(collectionBaseOperators)
        );
    }
}

contract NFTFactoryDirectUpgrade is NFTFactoryHelper, Test {
    function setUp() public {
        implementation = new SygnumERC1155();
        factoryImplementationV2 = new NFTFactoryV2();
        factoryProxy = new NFTFactoryProxy(address(factoryImplementationV2), proxyAdmin, "");
        factoryV2 = NFTFactoryV2(address(factoryProxy));
        baseOperators = new BaseOperators(admin);
        collectionBaseOperators = new BaseOperators(admin);

        vm.prank(admin);
        baseOperators.addOperator(operator);

        factoryV2.initialize(
            address(implementation),
            proxyAdmin,
            address(baseOperators),
            address(collectionBaseOperators)
        );
    }

    function testImplementationSetCorrectly() public {
        vm.prank(proxyAdmin);
        assertEq(factoryProxy.implementation(), address(factoryImplementationV2));
    }

    function testCannotReinitializeV2() public {
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryV2AlreadyInitialized()"));
        factoryV2.initializeV2(address(collectionBaseOperators));
    }

    function testCannotReinitializeMain() public {
        vm.expectRevert(abi.encodeWithSignature("InitializableContractAlreadyInitialized()"));
        factoryV2.initialize(
            address(implementation),
            proxyAdmin,
            address(baseOperators),
            address(collectionBaseOperators)
        );

        vm.expectRevert(abi.encodeWithSignature("InitializableContractAlreadyInitialized()"));
        factoryV2.initialize(address(implementation), proxyAdmin, address(baseOperators));
    }
}

contract NFTFactoryFunctionsTest is NFTFactoryHelper, Test {
    using stdStorage for StdStorage;

    address royaltyRecipient = admin;
    string baseUri = "https://sygnum.com/";
    uint256 startDate = block.timestamp;
    uint256 mintDuration = 10 days;

    function setUp() public {
        implementation = new SygnumERC1155();
        factoryImplementationV2 = new NFTFactoryV2();
        factoryProxy = new NFTFactoryProxy(address(factoryImplementationV2), proxyAdmin, "");
        factoryV2 = NFTFactoryV2(address(factoryProxy));
        baseOperators = new BaseOperators(admin);
        collectionBaseOperators = new BaseOperators(admin);

        vm.prank(admin);
        baseOperators.addOperator(operator);

        factoryV2.initialize(
            address(implementation),
            proxyAdmin,
            address(baseOperators),
            address(collectionBaseOperators)
        );
    }

    function testNewCollectionCreation() public {
        vm.prank(operator);
        factoryV2.newCollection(
            name,
            symbol,
            encodedMaxTokenSupplies,
            royaltyRecipient,
            baseUri,
            startDate,
            mintDuration
        );
    }
}
