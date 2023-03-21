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
            (address _impl, address _admin, address _baseOperators) = (
                vm.envAddress("CONTRACT_COLLECTION_IMPLEMENTATION"),
                vm.envAddress("CONTRACT_COLLECTION_ADMIN"),
                vm.envAddress("CONTRACT_FACTORY_BASE_OPERATORS")
            );

            initializePayload = abi.encodeWithSignature(
                "initialize(address,address,address)",
                _impl,
                _admin,
                _baseOperators
            );
        } else if (version == 2) {
            address _collectionBaseOperators = vm.envAddress("CONTRACT_COLLECTION_BASE_OPERATORS");
            initializePayload = abi.encodeWithSignature("initializeV2(address)", _collectionBaseOperators);
        } else {
            revert("Invalid version.");
        }
        string memory fullCalldata = vm.toString(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", implementation, initializePayload)
        );
        console.log(fullCalldata);
        vm.writeFile("./upgradeToAndCall.txt", fullCalldata);
    }
}
