// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {PubdataChunkPublisher} from "contracts/PubdataChunkPublisher.sol";
import {BLOB_SIZE_BYTES, MAX_NUMBER_OF_BLOBS} from "contracts/Constants.sol";

contract PubdataChunkPublisherTest is Test {
    function test_TooMuchPubdata_reverts() public {
        PubdataChunkPublisher p = new PubdataChunkPublisher();
        uint256 tooBig = BLOB_SIZE_BYTES * MAX_NUMBER_OF_BLOBS + 1;
        bytes memory pubdata = new bytes(tooBig);
        vm.expectRevert();
        p.chunkPubdataToBlobs(pubdata);
    }
}

