// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import "../contracts/SygnumERC1155.sol";
import "../contracts/factory/NFTFactoryV1.sol";
import "../contracts/NFTFactoryProxy.sol";

import "../contracts/interfaces/ISygnumERC1155.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/BaseOperators.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract NFTFactoryHelper {
    NFTFactoryV1 factory;
    NFTFactoryProxy factoryProxy;
    NFTFactoryV1 factoryImplementation;
    SygnumERC1155 implementation;
    BaseOperators baseOperators;
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

contract NFTFactorySetupTest is NFTFactoryHelper, Test {
    function setUp() public {
        implementation = new SygnumERC1155();
        factoryImplementation = new NFTFactoryV1();
        factoryProxy = new NFTFactoryProxy(address(factoryImplementation), proxyAdmin, "");
        factory = NFTFactoryV1(address(factoryProxy));
        baseOperators = new BaseOperators(admin);

        vm.prank(admin);
        baseOperators.addOperator(operator);
    }

    function testInitializeVariablesCorrectly() public {
        factory.initialize(address(implementation), proxyAdmin, address(baseOperators));

        assertEq(factory.implementation(), address(implementation));
        assertEq(factory.proxyAdmin(), proxyAdmin);
        assertEq(factory.getOperatorsContract(), address(baseOperators));
    }

    function testImplementationCannotBeInitialized() public {
        vm.expectRevert(abi.encodeWithSignature("InitializableContractAlreadyInitialized()"));
        factoryImplementation.initialize(address(implementation), proxyAdmin, address(baseOperators));
    }

    function testRevertsOnInvalidBaseOperators() public {
        assertEq(address(0).code.length, 0);
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryInvalidBaseOperators()"));
        factory.initialize(address(implementation), proxyAdmin, address(0));
    }

    function testRevertsOnZeroImplementation() public {
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryNewImplementationIsZeroAddress()"));
        factory.initialize(address(0), admin, address(baseOperators));
    }

    function testRevertsOnZeroProxyAdmin() public {
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryNewProxyAdminIsZeroAddress()"));
        factory.initialize(address(implementation), address(0), address(baseOperators));
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
        factoryImplementation = new NFTFactoryV1();
        factoryProxy = new NFTFactoryProxy(address(factoryImplementation), proxyAdmin, "");
        factory = NFTFactoryV1(address(factoryProxy));
        encodedMaxTokenSupplies = hex"0000a4dcf100ff8f10092bde";
        baseOperators = new BaseOperators(admin);

        vm.prank(admin);
        baseOperators.addOperator(operator);

        factory.initialize(address(implementation), admin, address(baseOperators));
    }

    function deployCollection() internal returns (ISygnumERC1155 collection) {
        address proxy = factory.newCollection(
            name,
            symbol,
            encodedMaxTokenSupplies,
            royaltyRecipient,
            address(baseOperators),
            baseUri,
            startDate,
            mintDuration
        );

        collection = ISygnumERC1155(proxy);
    }

    function testDeployedCollectionInitialized() public {
        vm.prank(operator);
        ISygnumERC1155 collection = deployCollection();

        assertEq(collection.startDate(), startDate);
        assertEq(collection.mintDuration(), mintDuration);
        assertEq(collection.baseUri(), baseUri);
        assertEq(collection.getOperatorsContract(), address(baseOperators));
        assertEq(collection.encodedMaxTokenSupplies(), encodedMaxTokenSupplies);
        assertEq(collection.maxUniqueTokens(), encodedMaxTokenSupplies.length / 2);

        (address _royaltyRecipient, ) = collection.royaltyInfo(0, 0);
        assertEq(_royaltyRecipient, royaltyRecipient);
    }

    function testChangeImplementationFromOperator() public {
        SygnumERC1155 newImplementation = new SygnumERC1155();

        vm.prank(operator);
        vm.expectEmit(false, false, false, false);
        emit ImplementationChanged(address(newImplementation));
        factory.changeImplementation(address(newImplementation));

        assertEq(factory.implementation(), address(newImplementation));
    }

    function testChangeProxyAdminFromOperator() public {
        vm.prank(operator);
        address newProxyAdmin = address(0xBEEF);

        vm.expectEmit(true, true, true, true);
        emit ProxyAdminChanged(newProxyAdmin);
        factory.changeProxyAdmin(newProxyAdmin);

        assertEq(factory.proxyAdmin(), newProxyAdmin);
    }

    function testCannotChangeImplementationToZeroAddress() public {
        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryNewImplementationIsZeroAddress()"));
        factory.changeImplementation(address(0));
    }

    function testCannotChangeProxyAdminToZeroAddress() public {
        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryNewProxyAdminIsZeroAddress()"));
        factory.changeProxyAdmin(address(0));
    }

    function testCannotChangeImplementationToSameAddress() public {
        address currentImplementation = factory.implementation();

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryNewImplementationIsSameAddress()"));
        factory.changeImplementation(currentImplementation);
    }

    function testCannotChangeProxyAdminToSameAddress() public {
        address currentProxyAdmin = factory.proxyAdmin();

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("NFTFactoryNewProxyAdminIsSameAddress()"));
        factory.changeProxyAdmin(currentProxyAdmin);
    }

    function testCannotChangeImplementationFromAttacker(address attacker) public {
        vm.assume(attacker != address(0));
        vm.assume(!factory.isOperator(attacker));
        vm.assume(attacker != proxyAdmin);

        vm.startPrank(attacker);

        SygnumERC1155 newImplementation = new SygnumERC1155();

        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        factory.changeImplementation(address(newImplementation));
    }

    function testCannotChangeProxyAdminFromAttacker(address attacker) public {
        vm.assume(attacker != address(0));
        vm.assume(!factory.isOperator(attacker));
        vm.assume(attacker != proxyAdmin);

        vm.startPrank(attacker);

        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        factory.changeProxyAdmin(attacker);
    }

    function testRecordDeployedProxies() public {
        vm.prank(operator);
        vm.expectEmit(false, false, false, false);
        // we emit an event with dummy address because it isn't knowable beforehand
        emit NewCollection(0, address(0));
        address proxy = address(deployCollection());
        assertEq(factory.deployedCollections(0), proxy);
        vm.expectRevert();
        factory.deployedCollections(1);
    }
}
