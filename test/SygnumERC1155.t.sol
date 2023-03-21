// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/Test.sol";
import "../contracts/SygnumERC1155.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/BaseOperators.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract SygnumERC1155Helper {
    SygnumERC1155 nftImplementation;
    SygnumERC1155 nft;
    TransparentUpgradeableProxy nftProxy;
    BaseOperators baseOperators;
    address proxyAdmin = address(1);
    address admin = address(2);

    string name = "SygnumERC1155";
    string symbol = "SYG1155";
    uint256 maxUniqueTokens;
    bytes encodedMaxTokenSupplies;
    string uri;

    uint256 mintDuration;
}

contract SygnumERC155SetupTest is SygnumERC1155Helper, Test {
    function setUp() public {
        baseOperators = new BaseOperators(admin);
        nftImplementation = new SygnumERC1155();
        nftProxy = new TransparentUpgradeableProxy(address(nftImplementation), proxyAdmin, "");
        nft = SygnumERC1155(address(nftProxy));
    }

    function testInitializeSetsVariablesCorrectly(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri
    ) public {
        vm.assume(_encodedMaxTokenSupplies.length > 0);
        vm.assume(_encodedMaxTokenSupplies.length % 2 == 0);
        vm.assume(_royaltyRecipient != address(0));
        vm.assume(bytes(_baseUri).length > 0);

        nft.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            _royaltyRecipient,
            address(baseOperators),
            _baseUri,
            block.timestamp,
            10 days
        );

        assertEq(nft.name(), name);
        assertEq(nft.symbol(), symbol);
        assertEq(nft.encodedMaxTokenSupplies(), _encodedMaxTokenSupplies);
        assertEq(nft.maxUniqueTokens(), _encodedMaxTokenSupplies.length / 2);
        assertEq(nft.baseUri(), _baseUri);
        assertEq(nft.startDate(), block.timestamp);
        assertEq(nft.mintDuration(), 10 days);

        (address royaltyRecipient, ) = nft.royaltyInfo(0, 0);
        assertEq(_royaltyRecipient, royaltyRecipient);
    }

    function testImplementationCannotBeInitialized(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri
    ) public {
        vm.expectRevert(abi.encodeWithSignature("InitializableContractAlreadyInitialized()"));
        nftImplementation.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            _royaltyRecipient,
            address(baseOperators),
            _baseUri,
            block.timestamp,
            10 days
        );
    }

    function testRevertsOnInvalidBaseOperators(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri
    ) public {
        vm.assume(_encodedMaxTokenSupplies.length > 0);
        vm.assume(_encodedMaxTokenSupplies.length % 2 == 0);
        vm.assume(_royaltyRecipient != address(0));
        vm.assume(bytes(_baseUri).length > 0);

        assertEq(address(0).code.length, 0);

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidBaseOperators()"));
        nft.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            _royaltyRecipient,
            address(0),
            _baseUri,
            block.timestamp,
            10 days
        );
    }

    function testRevertsOnInvalidRoyaltyRecipient(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri
    ) public {
        vm.assume(_encodedMaxTokenSupplies.length > 0);
        vm.assume(_encodedMaxTokenSupplies.length % 2 == 0);
        vm.assume(_royaltyRecipient != address(0));
        vm.assume(bytes(_baseUri).length > 0);

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155RoyaltyRecipientIsZeroAddress()"));
        nft.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            address(0),
            address(baseOperators),
            _baseUri,
            block.timestamp,
            10 days
        );
    }

    function testRevertsOnInvalidBaseUri(bytes calldata _encodedMaxTokenSupplies, address _royaltyRecipient) public {
        vm.assume(_encodedMaxTokenSupplies.length > 0);
        vm.assume(_encodedMaxTokenSupplies.length % 2 == 0);
        vm.assume(_royaltyRecipient != address(0));

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidBaseUri()"));
        nft.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            _royaltyRecipient,
            address(baseOperators),
            "",
            block.timestamp,
            10 days
        );
    }

    function testRevertsOnInvalidMaxTokenSupplies(address _royaltyRecipient, string memory _baseUri) public {
        vm.assume(_royaltyRecipient != address(0));
        vm.assume(bytes(_baseUri).length > 0);

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidMaxTokenSupplies()"));
        nft.initialize(
            name,
            symbol,
            hex"00b419",
            _royaltyRecipient,
            address(baseOperators),
            _baseUri,
            block.timestamp,
            10 days
        );
    }

    function testRevertsOnInvalidMintDuration(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri
    ) public {
        vm.assume(_encodedMaxTokenSupplies.length > 0);
        vm.assume(_encodedMaxTokenSupplies.length % 2 == 0);
        vm.assume(_royaltyRecipient != address(0));
        vm.assume(bytes(_baseUri).length > 0);

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidMintDuration()"));
        nft.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            _royaltyRecipient,
            address(baseOperators),
            _baseUri,
            uint256(0),
            10 days
        );
    }

    function testRevertsOnInvalidMintDuration2(
        bytes calldata _encodedMaxTokenSupplies,
        address _royaltyRecipient,
        string memory _baseUri
    ) public {
        vm.assume(_encodedMaxTokenSupplies.length > 0);
        vm.assume(_encodedMaxTokenSupplies.length % 2 == 0);
        vm.assume(_royaltyRecipient != address(0));
        vm.assume(bytes(_baseUri).length > 0);

        skip(10 days);

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidMintDuration()"));
        nft.initialize(
            name,
            symbol,
            _encodedMaxTokenSupplies,
            _royaltyRecipient,
            address(baseOperators),
            _baseUri,
            block.timestamp - 5 days,
            2 days
        );
    }

    function testOperatorsSetCorrectly(address operator, address attacker) public {
        vm.assume(operator != attacker);
        vm.assume(operator != address(0));
        vm.assume(attacker != address(0));

        vm.prank(admin);
        baseOperators.addOperator(operator);

        assertEq(baseOperators.isOperator(operator), true);
        assertEq(baseOperators.isOperator(attacker), false);
    }
}

contract SygnumERC1155FunctionsTest is SygnumERC1155Helper, Test {
    using Address for address;
    using stdStorage for StdStorage;

    address operator = address(2);
    address system = address(3);

    function setUp() public {
        // block.timestamp is 0 during tests, so we forward to avoid underflows on rewinds
        skip(100 days);

        nftImplementation = new SygnumERC1155();
        nftProxy = new TransparentUpgradeableProxy(address(nftImplementation), proxyAdmin, "");
        nft = SygnumERC1155(address(nftProxy));
        baseOperators = new BaseOperators(admin);

        encodedMaxTokenSupplies = hex"0000a4dcf100ff8f10092bde";
        uri = "https://sygnum.com/";

        mintDuration = 10 days;

        nft.initialize(
            name,
            symbol,
            encodedMaxTokenSupplies,
            admin,
            address(baseOperators),
            uri,
            block.timestamp,
            mintDuration
        );

        vm.startPrank(admin);
        baseOperators.addOperator(operator);
        baseOperators.addSystem(system);
        vm.stopPrank();
    }

    function sendToken(address account, uint256 tokenId) internal {
        vm.prank(operator);
        nft.mint(account, tokenId, 1, "");
    }

    function sendTokens(
        address account,
        uint256[] memory tokenIds,
        uint256[] memory quantities
    ) internal {
        vm.prank(operator);
        nft.batchMint(account, tokenIds, quantities, "");
    }

    function ids() internal pure returns (uint256[] memory _ids) {
        _ids = new uint256[](2);
        _ids[0] = 1;
        _ids[1] = 2;
    }

    function amounts() internal pure returns (uint256[] memory _amounts) {
        _amounts = new uint256[](2);
        _amounts[0] = 2;
        _amounts[1] = 4;
    }

    function ids300() internal pure returns (uint256[] memory _ids) {
        _ids = new uint256[](300);
        for (uint256 i = 0; i < 300; i++) {
            _ids[i] = 1;
        }
    }

    function amounts300() internal pure returns (uint256[] memory _amounts) {
        _amounts = new uint256[](300);
        for (uint256 i = 0; i < 300; i++) {
            _amounts[i] = 1;
        }
    }

    function testUri() public {
        assertEq(nft.uri(2), string(abi.encodePacked(uri, "2.json")));
    }

    function testBytesEncoding() public {
        uint256[6] memory decodedSupplies = [uint256(0), 42204, 61696, 65423, 4105, 11230];

        for (uint256 i = 0; i < decodedSupplies.length; ++i) {
            assertEq(nft.maxTokenSupply(i), decodedSupplies[i]);
        }
    }

    // TESTING safeTransferFrom
    function testCanSafeTransferFrom() public {
        address from = address(0xABC);
        address to = address(0xDEF);

        sendToken(from, 1);

        assertEq(nft.isPaused(), false);
        vm.prank(from);
        nft.safeTransferFrom(from, to, 1, 1, "");
    }

    // TESTING safeBatchTransferFrom
    function testCanBatchSafeTransferFrom() public {
        address from = address(0xABC);
        address to = address(0xDEF);

        sendTokens(from, ids(), amounts());

        assertEq(nft.isPaused(), false);
        vm.prank(from);
        nft.safeBatchTransferFrom(from, to, ids(), amounts(), "");
    }

    function testCannotBatchSafeTransferFromOverLimit() public {
        address from = address(0xABC);
        address to = address(0xDEF);

        sendTokens(from, ids(), amounts());

        vm.prank(from);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155BatchLimitExceeded()"));
        nft.safeBatchTransferFrom(from, to, ids300(), amounts300(), "");
    }

    // TESTING mint

    function testOperatorCanMint() public {
        vm.prank(operator);
        nft.mint(operator, 2, 1, "");
    }

    function testCannotMintInvalidTokenId() public {
        vm.startPrank(operator);
        uint256 maxSupply = nft.maxUniqueTokens();

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidTokenID()"));
        nft.mint(operator, maxSupply, 1, "");

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidTokenID()"));
        nft.mint(operator, maxSupply + 1, 1, "");
    }

    function testCannotMintZeroAmount() public {
        vm.startPrank(operator);

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingZeroAmount()"));
        nft.mint(operator, 1, 0, "");
    }

    function testNonOperatorCannotMint(address attacker) public {
        vm.assume(attacker != address(0));
        vm.assume(attacker != proxyAdmin);
        vm.assume(!baseOperators.isOperator(attacker));

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        nft.mint(attacker, 1, 1, "");

        vm.prank(system);
        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        nft.mint(system, 1, 1, "");
    }

    function testCannotMintOverSupply(uint256 id) public {
        uint256 tokenNumber = nft.maxUniqueTokens();
        uint256 maxAmount = nft.maxTokenSupply(id % tokenNumber);
        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155AmountExceedsMaxSupply()"));

        nft.mint(operator, id % tokenNumber, maxAmount + 1, "");
    }

    function testCannotMintOutsideMintingPeriod() public {
        // before minting period
        rewind(2 days);
        assertEq(block.timestamp < nft.startDate(), true);

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingNotStarted()"));
        nft.mint(operator, 1, 1, "");

        // after minting period
        skip(15 days);
        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingEnded()"));
        nft.mint(operator, 1, 1, "");
    }

    function testCanMintOpenEndedWhenPeriodIsZero() public {
        // change duration of mint to zero
        stdstore.target(address(nft)).sig(nft.mintDuration.selector).checked_write(uint256(0));

        skip(15 days);

        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);
        vm.prank(operator);
        nft.mint(operator, 1, 1, "");

        rewind(100 days);

        assertEq(block.timestamp < nft.startDate(), true);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingNotStarted()"));
        vm.prank(operator);
        nft.mint(operator, 1, 1, "");
    }

    function testCanMintAnytimeWhenStartDateIsZero() public {
        // change start date to zero
        stdstore.target(address(nft)).sig(nft.startDate.selector).checked_write(uint256(0));

        skip(15 days);

        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);
        vm.prank(operator);
        nft.mint(operator, 1, 1, "");

        // change mint duration to zero
        stdstore.target(address(nft)).sig(nft.mintDuration.selector).checked_write(uint256(0));

        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);
        vm.prank(operator);
        nft.mint(operator, 1, 1, "");
    }

    // TESTING batchMint

    function testOperatorCanBatchMint() public {
        vm.prank(operator);
        nft.batchMint(operator, ids(), amounts(), "");
    }

    function testCannotBatchMintOverBatchLimit() public {
        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155BatchLimitExceeded()"));
        nft.batchMint(operator, ids300(), amounts300(), "");
    }

    function testCannotBatchMintInvalidTokenId() public {
        vm.startPrank(operator);
        uint256 maxSupply = nft.maxUniqueTokens();
        uint256[] memory _ids = new uint256[](2);
        _ids[0] = 1;
        _ids[1] = maxSupply;

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidTokenID()"));
        nft.batchMint(operator, _ids, amounts(), "");

        _ids[0] = 1;
        _ids[1] = maxSupply + 1;

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155InvalidTokenID()"));
        nft.batchMint(operator, _ids, amounts(), "");
    }

    function testCannotBatchMintOnMismatchingInputSize() public {
        vm.startPrank(operator);
        uint256[] memory _ids = new uint256[](1);
        _ids[0] = 1;

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MismatchingInputSize()"));
        nft.batchMint(operator, _ids, amounts(), "");
    }

    function testCannotBatchMintOverSupply(uint256[] memory _ids) public {
        vm.startPrank(operator);
        vm.assume(_ids.length > 0);
        uint256 tokenNumber = nft.maxUniqueTokens();

        uint256[] memory _amounts = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _amounts[i] = nft.maxTokenSupply(_ids[i] % tokenNumber) + 1;
            _ids[i] = _ids[i] % tokenNumber;
        }

        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155AmountExceedsMaxSupply()"));
        nft.batchMint(operator, _ids, _amounts, "");
    }

    function testCannotBatchMintOutsideMintingPeriod() public {
        // before minting period
        rewind(2 days);
        assertEq(block.timestamp < nft.startDate(), true);

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingNotStarted()"));
        nft.batchMint(operator, ids(), amounts(), "");

        // after minting period
        skip(15 days);
        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingEnded()"));
        nft.batchMint(operator, ids(), amounts(), "");
    }

    function testCanBatchMintOpenEndedWhenPeriodIsZero() public {
        // change duration of mint to zero
        stdstore.target(address(nft)).sig(nft.mintDuration.selector).checked_write(uint256(0));

        skip(15 days);

        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);
        vm.prank(operator);
        nft.batchMint(operator, ids(), amounts(), "");

        rewind(100 days);

        assertEq(block.timestamp < nft.startDate(), true);
        vm.expectRevert(abi.encodeWithSignature("SygnumERC1155MintingNotStarted()"));
        vm.prank(operator);
        nft.batchMint(operator, ids(), amounts(), "");
    }

    function testCanBatchMintAnytimeWhenStartDateIsZero() public {
        // change start date to zero
        stdstore.target(address(nft)).sig(nft.startDate.selector).checked_write(uint256(0));

        skip(15 days);

        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);
        vm.prank(operator);
        nft.batchMint(operator, ids(), amounts(), "");

        // change mint duration to zero
        stdstore.target(address(nft)).sig(nft.mintDuration.selector).checked_write(uint256(0));

        assertEq(block.timestamp > nft.startDate() + nft.mintDuration(), true);
        vm.prank(operator);
        nft.batchMint(operator, ids(), amounts(), "");
    }

    function testNonOperatorCannotBatchMint(address attacker) public {
        vm.assume(attacker != address(0));
        vm.assume(attacker != proxyAdmin);
        vm.assume(!baseOperators.isOperator(attacker));

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        nft.batchMint(attacker, ids(), amounts(), "");

        vm.prank(system);
        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        nft.batchMint(system, ids(), amounts(), "");
    }

    // TESTING setDefaultRoyalty

    function testSetDefaultRoyalty(address newRecipient, uint96 feeNumerator) public {
        vm.assume(newRecipient != address(0));
        vm.assume(feeNumerator <= 10000);

        (address recipient, uint256 amount) = nft.royaltyInfo(0, 1 ether);
        assertEq(recipient, admin);
        assertEq(amount, 0);

        vm.prank(operator);
        nft.setDefaultRoyalty(newRecipient, feeNumerator);

        (recipient, amount) = nft.royaltyInfo(0, 1 ether);
        assertEq(recipient, newRecipient);
        assertEq(amount, (1 ether * feeNumerator) / 10000);
    }

    function testNonOperatorCannotSetDefaultRoyalty(address attacker) public {
        vm.assume(attacker != address(0));
        vm.assume(!baseOperators.isOperator(attacker));
        vm.assume(attacker != proxyAdmin);

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("OperatorableCallerNotOperator()"));
        nft.setDefaultRoyalty(address(3), 10);
    }

    // TESTING supportsInterface

    function testSupportsInterface() public {
        assertEq(nft.supportsInterface(type(IERC2981).interfaceId), true);
        assertEq(nft.supportsInterface(0xd9b67a26), true); // ERC165 Interface ID for ERC1155
        assertEq(nft.supportsInterface(0x0e89341c), true); // ERC165 Interface ID for ERC1155MetadataURI
        assertEq(nft.supportsInterface(type(IERC165).interfaceId), true);
    }
}
