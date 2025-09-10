// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {L1NativeTokenVault} from "contracts/bridge/ntv/L1NativeTokenVault.sol";
import {IL1Nullifier} from "contracts/bridge/interfaces/IL1Nullifier.sol";
import {IBridgehub} from "contracts/bridgehub/IBridgehub.sol";
import {IL1ERC20Bridge} from "contracts/bridge/interfaces/IL1ERC20Bridge.sol";
import {IL1NativeTokenVault} from "contracts/bridge/ntv/IL1NativeTokenVault.sol";
import {DataEncoding} from "contracts/common/libraries/DataEncoding.sol";
import {ETH_TOKEN_ADDRESS} from "contracts/common/Config.sol";

contract DummyNullifier is IL1Nullifier {
	function BRIDGE_HUB() external view returns (IBridgehub) { return IBridgehub(address(0)); }
	function isWithdrawalFinalized(uint256, uint256, uint256) external view returns (bool) { return false; }
	function legacyBridge() external view returns (IL1ERC20Bridge) { return IL1ERC20Bridge(address(0)); }
	function l1NativeTokenVault() external view returns (IL1NativeTokenVault) { return IL1NativeTokenVault(address(0)); }
	function setL1NativeTokenVault(IL1NativeTokenVault) external {}
	function setL1AssetRouter(address) external {}
	function l2BridgeAddress(uint256) external view returns (address) { return address(0); }
	function depositHappened(uint256, bytes32) external view returns (bytes32) { return bytes32(0); }
	function finalizeDeposit(FinalizeL1DepositParams calldata) external {}
	function bridgeRecoverFailedTransfer(uint256, address, bytes32, bytes memory, bytes32, uint256, uint256, uint16, bytes32[] calldata) external {}
	function claimFailedDepositLegacyErc20Bridge(address, address, uint256, bytes32, uint256, uint256, uint16, bytes32[] calldata) external {}
	function claimFailedDeposit(uint256, address, address, uint256, bytes32, uint256, uint256, uint16, bytes32[] calldata) external {}
	function bridgehubConfirmL2TransactionForwarded(uint256, bytes32, bytes32) external {}
	function chainBalance(uint256, address) external pure returns (uint256) { return 0; }
	function nullifyChainBalanceByNTV(uint256, address) external pure {}
	function transferTokenToNTV(address) external pure {}
}

contract DummyRouter { }

contract L1NativeTokenVaultInvariants is Test {
	L1NativeTokenVault internal ntv;
	DummyNullifier internal nullifier;
	DummyRouter internal router;

	function setUp() public {
		nullifier = new DummyNullifier();
		router = new DummyRouter();
		ntv = new L1NativeTokenVault(address(0), address(router), IL1Nullifier(address(nullifier)));
		ntv.initialize(address(this), address(0));
		ntv.registerEthToken();
	}

	function test_chainBalanceDecreaseRevertsOnInsufficientBalance() public {
		bytes32 assetId = DataEncoding.encodeNTVAssetId(block.chainid, ETH_TOKEN_ADDRESS);
		vm.startPrank(address(router));
		vm.expectRevert();
		ntv.bridgeRecoverFailedTransfer({
			_chainId: 9,
			_assetId: assetId,
			_depositSender: address(this),
			_data: DataEncoding.encodeBridgeBurnData(1, address(0), address(0))
		});
		vm.stopPrank();
	}
}

