// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MailboxTest} from "./_Mailbox_Shared.t.sol";
import {IMailbox} from "contracts/state-transition/chain-interfaces/IMailbox.sol";
import {L2Log} from "contracts/common/Messaging.sol";
import {AddressAliasHelper} from "contracts/vendor/AddressAliasHelper.sol";

contract MailboxProofMetadataTest is MailboxTest {
    function setUp() public {
        setupDiamondProxy();
    }

    function _makeMetadata(bytes1 version, bytes1 logLeafLen, bytes1 batchLeafLen, bytes1 finalFlag)
        internal
        pure
        returns (bytes32)
    {
        // Layout: [version][logLeafLen][batchLeafLen][finalFlag][28 zero bytes]
        return bytes32(abi.encodePacked(version, logLeafLen, batchLeafLen, finalFlag, bytes28(0)));
    }

    function test_MetadataVersionUnsupported_reverts() public {
        // version 0x02 (unsupported), logLeafProofLen=1, batchLeafProofLen=0, finalFlag=true
        bytes32 meta = _makeMetadata(0x02, 0x01, 0x00, 0x01);
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = meta;
        proof[1] = bytes32(uint256(1)); // dummy element to satisfy length

        // Minimal dummy log and params; reverts during metadata parse before further checks
        L2Log memory dummyLog = L2Log({
            l2ShardId: 0,
            isService: true,
            txNumberInBatch: 0,
            sender: address(0),
            key: bytes32(0),
            value: bytes32(0x01)
        });

        vm.expectRevert();
        mailboxFacet.proveL2LogInclusion({
            _batchNumber: 0,
            _index: 0,
            _log: dummyLog,
            _proof: proof
        });
    }

    function test_FinalProofNodeWithNonzeroBatchProofLen_reverts() public {
        // version 0x01 (supported), logLeafProofLen=1, batchLeafProofLen=1, finalFlag=true -> invalid
        bytes32 meta = _makeMetadata(0x01, 0x01, 0x01, 0x01);
        // Need at least 1 (meta) + logLeafProofLen (1) + 1 (batch mask) + batchLeafProofLen (1) elements
        bytes32[] memory proof = new bytes32[](4);
        proof[0] = meta;
        proof[1] = bytes32(uint256(1)); // log path element
        proof[2] = bytes32(uint256(0)); // batch mask (packed)
        proof[3] = bytes32(uint256(1)); // batch path element

        L2Log memory dummyLog = L2Log({
            l2ShardId: 0,
            isService: true,
            txNumberInBatch: 0,
            sender: address(0),
            key: bytes32(0),
            value: bytes32(0x01)
        });

        vm.expectRevert();
        mailboxFacet.proveL2LogInclusion({
            _batchNumber: 0,
            _index: 0,
            _log: dummyLog,
            _proof: proof
        });
    }

    function test_GasPerPubdataMismatch_reverts_onBridgehubPath() public {
        // Prepare a request with wrong l2GasPerPubdataByteLimit
        IMailbox.BridgehubL2TransactionRequest memory req = IMailbox.BridgehubL2TransactionRequest({
            sender: address(0xdeadbeef),
            contractL2: address(0xc0ffee),
            mintValue: 0,
            l2Value: 0,
            l2GasLimit: 100_000,
            l2Calldata: hex"",
            l2GasPerPubdataByteLimit: 12345, // wrong constant
            factoryDeps: new bytes[](0),
            refundRecipient: address(0)
        });

        // Call as bridgehub (onlyBridgehub gate)
        vm.startPrank(bridgehub);
        vm.expectRevert();
        mailboxFacet.bridgehubRequestL2Transaction(req);
        vm.stopPrank();
    }
}

