// SPDX-License-Identifier: Unlicensed

/**
 * @title NFTFactoryProxy
 * @author Team 3301 <team3301@sygnum.com>
 * @dev Proxies SygnumToken calls and enables SygnumToken upgradability.
 */
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTFactoryProxy is TransparentUpgradeableProxy {
    /* solhint-disable no-empty-blocks */
    constructor(
        address implementation,
        address proxyOwnerAddr,
        bytes memory data
    ) TransparentUpgradeableProxy(implementation, proxyOwnerAddr, data) {}
    /* solhint-enable no-empty-blocks */
}
