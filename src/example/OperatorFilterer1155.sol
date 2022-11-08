// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";

abstract contract OperatorFilterer1155 {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from, uint256 id) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            _checkOperator(from, id);
        }
        _;
    }

    modifier onlyAllowedOperatorBatch(address from, uint256[] memory ids) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            uint256 idsLength = ids.length;
            unchecked {
                for (uint256 i = 0; i < idsLength; ++i) {
                    _checkOperator(from, ids[i]);
                }
            }
        }
        _;
    }

    function _checkOperator(address from, uint256 id) internal view {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from == msg.sender) {
            if (balanceOf(msg.sender, id) > 0) {
                return;
            }
        }
        if (
            !(
                operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
                    && operatorFilterRegistry.isOperatorAllowed(address(this), from)
            )
        ) {
            revert OperatorNotAllowed(msg.sender);
        }
    }

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 balance);
}