// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/Test.sol";
import {L1Nullifier} from "contracts/bridge/L1Nullifier.sol";
import {IL1AssetRouter} from "contracts/bridge/asset-router/IL1AssetRouter.sol";
import {IL1Nullifier} from "contracts/bridge/interfaces/IL1Nullifier.sol";
import {IL1ERC20Bridge} from "contracts/bridge/interfaces/IL1ERC20Bridge.sol";
import {INativeTokenVault} from "contracts/bridge/ntv/INativeTokenVault.sol";
import {IL1NativeTokenVault} from "contracts/bridge/ntv/IL1NativeTokenVault.sol";
import {IBridgehub, L2TransactionRequestTwoBridgesInner} from "contracts/bridgehub/IBridgehub.sol";
import {DataEncoding} from "contracts/common/libraries/DataEncoding.sol";
import {TxStatus} from "contracts/common/Messaging.sol";

contract DummyRouter is IL1AssetRouter {
	event Recovered(uint256 chainId, address sender, bytes32 assetId, bytes data);
	function BRIDGE_HUB() external view returns (IBridgehub) { return IBridgehub(address(0)); }
	function assetHandlerAddress(bytes32) external view returns (address) { return address(0); }
	function finalizeDeposit(uint256, bytes32, bytes memory) external payable {}
	function setAssetHandlerAddressThisChain(bytes32, address) external {}
	function transferFundsToNTV(bytes32, uint256, address) external pure returns (bool) { return true; }
	function L1_NULLIFIER() external view returns (IL1Nullifier) { return IL1Nullifier(address(0)); }
	function L1_WETH_TOKEN() external view returns (address) { return address(0); }
	function nativeTokenVault() external view returns (INativeTokenVault) { return INativeTokenVault(address(0)); }
	function setAssetDeploymentTracker(bytes32, address) external {}
	function setNativeTokenVault(INativeTokenVault) external {}
	function setL1Erc20Bridge(IL1ERC20Bridge) external {}
	function bridgeRecoverFailedTransfer(uint256, address, bytes32, bytes calldata) external {}
	function bridgeRecoverFailedTransfer(uint256, address, bytes32, bytes memory, bytes32, uint256, uint256, uint16, bytes32[] calldata) external {}
	function finalizeWithdrawal(uint256,uint256,uint256,uint16,bytes calldata,bytes32[] calldata) external {}
	function bridgehubDeposit(uint256,address,uint256,bytes calldata) external payable returns (L2TransactionRequestTwoBridgesInner memory request) {return request;}
	function getDepositCalldata(address,bytes32,bytes memory) external view returns (bytes memory) {return bytes("");}
	function bridgehubDepositBaseToken(uint256,bytes32,address,uint256) external payable {}
	function bridgehubConfirmL2Transaction(uint256,bytes32,bytes32) external {}
	function isWithdrawalFinalized(uint256,uint256,uint256) external view returns (bool) {return false;}
}

contract L1NullifierNewClaimFlowTest is Test {
	L1Nullifier internal nullifier;
	DummyRouter internal router;

	function setUp() public {
		router = new DummyRouter();
		nullifier = new L1Nullifier(IBridgehub(address(0)), 9, address(0));
		nullifier.initialize(address(this), 1, 1, type(uint256).max, 0);
		nullifier.setL1AssetRouter(address(router));
		// set a nonzero NTV address
		nullifier.setL1NativeTokenVault(IL1NativeTokenVault(address(0xdead)));
	}

	function test_NewFlow_AllowsRecoverOnProofSuccess() public {
		uint256 chainId = 11;
		address sender = address(0xBEEF);
		address l1Token = address(0xCAFE);
		bytes32 assetId = DataEncoding.encodeNTVAssetId(block.chainid, l1Token);
		bytes memory burnData = DataEncoding.encodeBridgeBurnData(1 ether, address(0), address(0));
		bytes32 txHash = keccak256("tx");
		bytes32 txDataHash = DataEncoding.encodeTxDataHash(0x01, sender, assetId, address(0xdead), burnData);

		// mock Bridgehub.proveL1ToL2TransactionStatus to return true
		bytes memory bhCalldata = abi.encodeWithSelector(IBridgehub.proveL1ToL2TransactionStatus.selector, chainId, txHash, 0, 0, uint16(0), new bytes32[](0), TxStatus.Failure);
		vm.mockCall(address(0), bhCalldata, abi.encode(true));

		// write deposit record mapping depositHappened[chainId][txHash] = txDataHash
		stdstore
			.target(address(nullifier))
			.sig("depositHappened(uint256,bytes32)")
			.with_key(chainId)
			.with_key(txHash)
			.checked_write(txDataHash);

		bytes32[] memory proof;
		// ensure no revert on successful proof path
		nullifier.bridgeRecoverFailedTransfer(chainId, sender, assetId, burnData, txHash, 0, 0, 0, proof);
	}
}

