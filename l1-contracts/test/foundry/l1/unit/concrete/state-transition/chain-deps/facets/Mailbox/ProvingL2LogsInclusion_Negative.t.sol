// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {L2Log} from "contracts/common/Messaging.sol";
import {InvalidProofLengthForFinalNode} from "contracts/common/L1ContractErrors.sol";
import {UnsupportedProofMetadataVersion} from "contracts/state-transition/L1StateTransitionErrors.sol";

import {MailboxTest} from "test/foundry/l1/unit/concrete/state-transition/chain-deps/facets/Mailbox/_Mailbox_Shared.t.sol";

contract MailboxMetadataNegative is MailboxTest {
    function setUp() public {
        setupDiamondProxy();
    }

    function _composeMetadata(uint8 proofLen, uint8 batchProofLen, bool finalNode) internal pure returns (bytes32) {
        return bytes32(
            bytes.concat(
                bytes1(uint8(0x01)),
                bytes1(proofLen),
                bytes1(batchProofLen),
                bytes1(finalNode ? uint8(1) : uint8(0)),
                bytes28(0)
            )
        );
    }

    function test_RevertWhen_InvalidMetadataVersion() public {
        // version != 0x01 should revert
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bytes32(
            bytes.concat(bytes1(uint8(0x02)), bytes1(uint8(0)), bytes1(uint8(0)), bytes1(uint8(1)), bytes28(0))
        );

        L2Log memory log = L2Log({
            l2ShardId: 0,
            isService: true,
            txNumberInBatch: 0,
            sender: address(0),
            key: bytes32(0),
            value: bytes32(0)
        });

        vm.expectRevert(abi.encodeWithSelector(UnsupportedProofMetadataVersion.selector, uint256(2)));
        mailboxFacet.proveL2LogInclusion({
            _batchNumber: 0,
            _index: 0,
            _log: log,
            _proof: proof
        });
    }

    function test_RevertWhen_FinalNodeWithNonZeroBatchProofLen() public {
        // finalProofNode == true but batchLeafProofLen != 0
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = _composeMetadata(0x01, 0x01, true);
        proof[1] = bytes32(uint256(0));

        L2Log memory log = L2Log({
            l2ShardId: 0,
            isService: true,
            txNumberInBatch: 0,
            sender: address(0),
            key: bytes32(0),
            value: bytes32(0)
        });

        vm.expectRevert(InvalidProofLengthForFinalNode.selector);
        mailboxFacet.proveL2LogInclusion({
            _batchNumber: 0,
            _index: 0,
            _log: log,
            _proof: proof
        });
    }
}

