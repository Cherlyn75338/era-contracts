// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {MessageRoot} from "contracts/bridgehub/MessageRoot.sol";
import {IBridgehub} from "contracts/bridgehub/IBridgehub.sol";

contract MessageRootUpdateFullTreeTest is Test {
    MessageRoot internal messageRoot;
    address internal bridgehub;

    function setUp() public {
        bridgehub = address(0);
        messageRoot = new MessageRoot(IBridgehub(bridgehub));
    }

    function test_updateFullTree_PermissionlessAndScalesWithChainCount() public {
        // Anyone can call updateFullTree (no access control)
        messageRoot.updateFullTree();

        // Grow chainCount via onlyBridgehub
        vm.startPrank(bridgehub);
        for (uint256 i = 1; i < 33; i++) {
            messageRoot.addNewChain(10_000 + i);
        }
        vm.stopPrank();

        uint256 gasBefore = gasleft();
        messageRoot.updateFullTree();
        uint256 gasAfter = gasleft();
        uint256 gasUsedSmall = gasBefore - gasAfter;

        // Add more chains to increase work
        vm.startPrank(bridgehub);
        for (uint256 i = 33; i < 97; i++) {
            messageRoot.addNewChain(10_000 + i);
        }
        vm.stopPrank();

        gasBefore = gasleft();
        messageRoot.updateFullTree();
        gasAfter = gasleft();
        uint256 gasUsedLarge = gasBefore - gasAfter;

        // Expect larger gas usage with more chains
        assertGt(gasUsedLarge, gasUsedSmall);
    }
}

