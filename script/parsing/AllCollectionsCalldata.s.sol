// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "contracts/SygnumERC1155.sol";
import "contracts/interfaces/INFTFactory.sol";

contract ParseCalldata is Script {
    struct Call {
        address target;
        bytes callData;
    }

    function setUp() public {}

    function getCollections(address factoryAddress) public returns (address[] memory) {
        INFTFactory factory = INFTFactory(factoryAddress);
        uint256 collectionCount = collectionCount(factoryAddress);
        address[] memory collections = new address[](collectionCount);

        console.log("collectionCount: ", collectionCount);
        for (uint256 i = 0; i < collectionCount; i++) {
            collections[i] = factory.deployedCollections(i);
        }

        return collections;
    }

    function collectionCount(address factoryAddress) public returns (uint256) {
        return uint256(vm.load(factoryAddress, bytes32(uint256(55)))); // starting slot for deployedCollections
    }

    function run() public {
        address implementation = vm.envAddress("CONTRACT_IMPLEMENTATION");
        address factory = vm.envAddress("CONTRACT_FACTORY");
        bytes memory initializePayload;

        uint256 version = vm.envUint("CONTRACT_INITIALIZER_VERSION");
        if (version == 1) {
            (
                string memory _name,
                string memory _symbol,
                bytes memory _encodedMaxTokenSupplies,
                address _royaltyRecipient,
                address _baseOperators,
                string memory _baseUri,
                uint256 _startDate,
                uint256 _mintDuration
            ) = (
                    vm.envString("CONTRACT_NAME"),
                    vm.envString("CONTRACT_SYMBOL"),
                    vm.envBytes("CONTRACT_MAX_TOKEN_SUPPLY"),
                    vm.envAddress("CONTRACT_ROYALTY_RECIPIENT"),
                    vm.envAddress("CONTRACT_BASE_OPERATORS"),
                    vm.envString("CONTRACT_BASE_URI"),
                    vm.envUint("CONTRACT_START_DATE"),
                    vm.envUint("CONTRACT_MINT_DURATION")
                );

            initializePayload = abi.encodeWithSignature(
                "initialize(string,string,bytes,address,address,string,uint256,uint256)",
                _name,
                _symbol,
                _encodedMaxTokenSupplies,
                _royaltyRecipient,
                _baseOperators,
                _baseUri,
                _startDate,
                _mintDuration
            );
        } else if (version == 2) {
            uint256 v2Variable = vm.envUint("CONTRACT_V2_VARIABLE");
            initializePayload = abi.encodeWithSignature("initializeV2(uint256)", v2Variable);
        }

        address[] memory targets = getCollections(factory);
        Call[] memory calls = new Call[](targets.length);
        bytes memory upgradeCalldata = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)",
            implementation,
            initializePayload
        );

        for (uint256 i = 0; i < targets.length; i++) {
            calls[i] = Call(targets[i], upgradeCalldata);
        }

        bytes memory fullCalldata = abi.encodeWithSignature("tryAggregate(bool,(address,bytes)[])", false, calls);

        console.log(vm.toString(fullCalldata));
        vm.writeFile("upgradeToAndCall.txt", vm.toString(fullCalldata));
    }
}
