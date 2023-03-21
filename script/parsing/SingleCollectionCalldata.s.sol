// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "contracts/SygnumERC1155.sol";

contract ParseCalldata is Script {
    function setUp() public {}

    function run() public {
        uint256 version = vm.envUint("CONTRACT_INITIALIZER_VERSION");
        address implementation = vm.envAddress("CONTRACT_IMPLEMENTATION");
        bytes memory initializePayload;
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

        string memory fullCalldata = vm.toString(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", implementation, initializePayload)
        );
        console.log(fullCalldata);
        vm.writeFile("./upgradeToAndCall.txt", fullCalldata);
    }
}
