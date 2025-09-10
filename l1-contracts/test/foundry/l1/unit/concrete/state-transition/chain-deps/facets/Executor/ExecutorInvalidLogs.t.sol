// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ExecutorTest} from "../_Executor_Shared.t.sol";
import {IExecutor} from "contracts/state-transition/chain-interfaces/IExecutor.sol";
import {Utils, DEFAULT_L2_LOGS_TREE_ROOT_HASH} from "../Utils/Utils.sol";

contract ExecutorInvalidLogsTest is ExecutorTest {
    function test_InvalidLogSender_reverts() public {
        // Craft system logs with wrong sender for L2_TO_L1_LOGS_TREE_ROOT_KEY
        bytes memory badLogs = Utils.encodePacked(Utils.createSystemLogsWithWrongSender(bytes32(0)));

        IExecutor.CommitBatchInfo memory badCommit = newCommitBatchInfo;
        badCommit.systemLogs = badLogs;

        IExecutor.StoredBatchInfo memory prev = genesisStoredBatchInfo;

        vm.startPrank(address(admin));
        // Expect revert during commit due to InvalidLogSender
        vm.expectRevert();
        executor.commitBatchesSharedBridge({
            _chainId: 0,
            _processFrom: 0,
            _processTo: 1,
            _commitData: Utils.packCommitData(prev, badCommit)
        });
        vm.stopPrank();
    }

    function test_MissingSystemLogs_reverts() public {
        // Craft system logs missing some required keys
        bytes memory missingLogs = Utils.encodePacked(Utils.createSystemLogsMissingKeys(bytes32(0)));
        IExecutor.CommitBatchInfo memory badCommit = newCommitBatchInfo;
        badCommit.systemLogs = missingLogs;
        IExecutor.StoredBatchInfo memory prev = genesisStoredBatchInfo;

        vm.startPrank(address(admin));
        vm.expectRevert();
        executor.commitBatchesSharedBridge({
            _chainId: 0,
            _processFrom: 0,
            _processTo: 1,
            _commitData: Utils.packCommitData(prev, badCommit)
        });
        vm.stopPrank();
    }
}

