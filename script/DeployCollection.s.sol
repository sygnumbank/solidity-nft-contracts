// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/factory/NFTFactoryV2.sol";
import "../contracts/SygnumERC1155.sol";
import "../contracts/NFTFactoryProxy.sol";
import "../contracts/interfaces/INFTFactory.sol";
import "@sygnum/solidity-base-contracts/contracts/role/base/BaseOperators.sol";

// Auditor wallet seedphrase: "nephew human account debris carpet cheese record must apart stage move friend"

contract DeployCollection is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("ETHEREUM_PRIVATE_KEY");
        address gnosisSafe = vm.envAddress("GNOSIS_SAFE");
        address deployer = vm.rememberKey(privateKey);

        vm.startBroadcast(deployer);

        SygnumERC1155 impl = new SygnumERC1155();
        NFTFactoryV2 factory = new NFTFactoryV2();
        BaseOperators factoryBaseOperators = new BaseOperators(deployer);
        BaseOperators collectionBaseOperators = new BaseOperators(deployer);

        // Deployer should have operator rights on factory only
        factoryBaseOperators.addOperator(vm.envAddress("CONTRACT_COLLECTION_DEPLOYER"));

        // Minter should have operator rights on collections only
        collectionBaseOperators.addOperator(vm.envAddress("CONTRACT_COLLECTION_MINTER"));

        // Change back baseOperators admin to Gnosis Safe
        factoryBaseOperators.addAdmin(gnosisSafe);
        collectionBaseOperators.addAdmin(gnosisSafe);

        NFTFactoryProxy factoryProxy = new NFTFactoryProxy(
            address(factory),
            gnosisSafe,
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(impl),
                gnosisSafe,
                address(factoryBaseOperators),
                address(collectionBaseOperators)
            )
        );

        vm.stopBroadcast();

        console.log("Factory proxy address:", address(factoryProxy), " deployed with calldata:");
        console.logBytes(
            abi.encode(
                address(factory),
                gnosisSafe,
                abi.encodeWithSignature(
                    "initialize(address,address,address)",
                    address(impl),
                    gnosisSafe,
                    address(factoryBaseOperators)
                )
            )
        );
        console.log("Factory implementation address:", address(factory));
        console.log("Implementation address:", address(impl));
        console.log("Factory BaseOperators address:", address(factoryBaseOperators), " deployed with calldata:");
        console.logBytes(abi.encode(deployer));
        console.log("Collection BaseOperators address:", address(collectionBaseOperators), " deployed with calldata:");
        console.logBytes(abi.encode(deployer));
        console.log("Collection deployer address:", vm.envAddress("CONTRACT_COLLECTION_DEPLOYER"));
        console.log("Collection minter address:", vm.envAddress("CONTRACT_COLLECTION_MINTER"));
    }
}
