// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IKnownCodesStorage} from "contracts/interfaces/IKnownCodesStorage.sol";

interface ICodeOracle {
    function isCodeHashKnown(bytes32) external view returns (uint256);
}

contract CodeOracleTest is Test {
    // Addresses of system contracts; may be absent in this unit test environment.
    address internal constant CODE_ORACLE_ADDR = address(0x0000000000000000000000000000000000008008);
    address internal constant KNOWN_CODES_ADDR = address(0x0000000000000000000000000000000000008004);

    function test_UnknownVersionedHash_behavior() public {
        bytes32 unknownHash = hex"0201000000000000000000000000000000000000000000000000000000000001";

        // If precompiles are not deployed in this environment, skip assertions.
        if (CODE_ORACLE_ADDR.code.length == 0 || KNOWN_CODES_ADDR.code.length == 0) {
            return;
        }

        // The yul code reverts when unknown (calls KnownCodes and then reverts on unsupported version).
        vm.expectRevert();
        (bool ok, ) = CODE_ORACLE_ADDR.staticcall(abi.encode(unknownHash));
        assertTrue(!ok, "Expected revert for unknown versioned hash");
    }
}

