// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IKnownCodesStorage} from "contracts/interfaces/IKnownCodesStorage.sol";

interface ICodeOracle {
    function isCodeHashKnown(bytes32) external view returns (uint256);
}

contract CodeOracleTest is Test {
    // CodeOracle is a precompile-like deployed system contract; tests here assert expected failure on unknown hash.
    address internal constant CODE_ORACLE_ADDR = address(0x0000000000000000000000000000000000008008);

    function test_UnknownVersionedHash_reverts() public {
        bytes32 unknownHash = hex"0201000000000000000000000000000000000000000000000000000000000001";
        (bool ok, ) = CODE_ORACLE_ADDR.staticcall(abi.encode(unknownHash));
        assertTrue(!ok, "Expected revert for unknown versioned hash");
    }
}

