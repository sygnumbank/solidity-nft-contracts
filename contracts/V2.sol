pragma solidity 0.8.8;

import "./SygnumERC1155.sol";

contract V2 is SygnumERC1155 {
    bool public initializedV2;

    error V2InitializeError();

    function initializeV2(uint256 v2Variable) public virtual {
        if (initializedV2) revert V2InitializeError();
        initializedV2 = true;
    }
}
