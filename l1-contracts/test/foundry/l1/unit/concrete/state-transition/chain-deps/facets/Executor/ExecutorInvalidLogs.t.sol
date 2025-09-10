// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ExecutorTest} from "../../../../Executor/_Executor_Shared.t.sol";
import {IExecutor, SystemLogKey} from "contracts/state-transition/chain-interfaces/IExecutor.sol";
import {Utils} from "../../../../Utils/Utils.sol";

contract ExecutorInvalidLogsTest is ExecutorTest {
	function test_InvalidLogSender_reverts() public {
		// Craft system logs with wrong sender by replacing the L2_TO_L1_LOGS_TREE_ROOT_KEY sender
		bytes[] memory logs = Utils.createSystemLogs(bytes32(0));
		// Overwrite first log to be from an incorrect sender (use bootloader address via Utils.constructL2Log)
		logs[0] = Utils.constructL2Log(
			true,
			address(0x0000000000000000000000000000000000008001),
			uint256(SystemLogKey.L2_TO_L1_LOGS_TREE_ROOT_KEY),
			bytes32("")
		);
		bytes memory badLogs = Utils.encodePacked(logs);

		IExecutor.CommitBatchInfo memory badCommit = newCommitBatchInfo;
		badCommit.systemLogs = badLogs;

		IExecutor.StoredBatchInfo memory prev = genesisStoredBatchInfo;

		vm.startPrank(address(admin));
		// Expect revert during commit due to InvalidLogSender
		vm.expectRevert();
		{
			IExecutor.CommitBatchInfo[] memory arr = new IExecutor.CommitBatchInfo[](1);
			arr[0] = badCommit;
			(uint256 fromBatch, uint256 toBatch, bytes memory commitData) = Utils.encodeCommitBatchesData(prev, arr);
			executor.commitBatchesSharedBridge(0, fromBatch, toBatch, commitData);
		}
		vm.stopPrank();
	}

	function test_MissingSystemLogs_reverts() public {
		// Craft system logs missing the PREV_BATCH_HASH_KEY by zeroing it out
		bytes[] memory logs2 = Utils.createSystemLogs(bytes32(0));
		// Remove PREV_BATCH_HASH_KEY by setting to zero value with correct sender to trigger MissingSystemLogs
		logs2[uint256(SystemLogKey.PREV_BATCH_HASH_KEY)] = Utils.constructL2Log(
			true,
			address(0x000000000000000000000000000000000000800B),
			uint256(SystemLogKey.PREV_BATCH_HASH_KEY),
			bytes32(0)
		);
		bytes memory missingLogs = Utils.encodePacked(logs2);
		IExecutor.CommitBatchInfo memory badCommit = newCommitBatchInfo;
		badCommit.systemLogs = missingLogs;
		IExecutor.StoredBatchInfo memory prev = genesisStoredBatchInfo;

		vm.startPrank(address(admin));
		vm.expectRevert();
		{
			IExecutor.CommitBatchInfo[] memory arr = new IExecutor.CommitBatchInfo[](1);
			arr[0] = badCommit;
			(uint256 fromBatch, uint256 toBatch, bytes memory commitData) = Utils.encodeCommitBatchesData(prev, arr);
			executor.commitBatchesSharedBridge(0, fromBatch, toBatch, commitData);
		}
		vm.stopPrank();
	}
}

