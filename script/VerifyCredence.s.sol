// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/// @title Verify Credence Contracts
/// @notice Verification script using Foundry's built-in verification
/// @dev Usage:
///   forge script script/VerifyCredence.s.sol --rpc-url $BASE_RPC_URL --broadcast --verify
///
///   Or verify individual contracts:
///   forge verify-contract 0xea2679e443bed949206c101e2533ed1390081fe5 TradeInfraEscrow --chain base --etherscan-api-key $ETHERSCAN_API_KEY
///
/// Environment variables:
///   BASE_RPC_URL       - Base mainnet RPC URL
///   ETHERSCAN_API_KEY  - Etherscan/Blockscout API key (for Basescan use your Etherscan key)
///   DEPLOYMENT_TIER   - Deployment tier used (LAUNCH, GROWTH, MATURE)
contract VerifyCredence is Script {
    // Base mainnet chain ID
    uint256 constant BASE_CHAIN_ID = 84532;

    // Deployed contract addresses (update these after deployment)
    address constant ESCROW_ADDRESS = 0xeA2679E443BEd949206C101E2533eD1390081FE5;
    address constant ORACLE_ADDRESS = 0x951Ec35799FCCc3D5D42F51dbf53312146F96B4B;
    address constant RECEIVABLE_ADDRESS = 0x3C21bee10beF5A5D82c75496071bc813f212F63D;

    function run() external {
        console.log("=== Credence Contract Verification ===");
        console.log("Chain ID: ", BASE_CHAIN_ID);
        console.log("");

        // These will be verified automatically when using --verify flag with forge script
        // The verification happens through the broadcast artifacts

        console.log("Contract addresses:");
        console.log("  TradeInfraEscrow:    ", ESCROW_ADDRESS);
        console.log("  CentralizedTradeOracle: ", ORACLE_ADDRESS);
        console.log("  CredenceReceivable: ", RECEIVABLE_ADDRESS);
        console.log("");
        console.log("To verify with forge, run:");
        console.log("  forge verify-contract --chain base --etherscan-api-key $ETHERSCAN_API_KEY");
        console.log("");

        // Note: The actual verification is handled by forge when using --verify flag
        // This script documents the verification process

        console.log("=== Verification Info ===");
        console.log("Compiler: solc 0.8.24");
        console.log("EVM Version: cancun");
        console.log("Optimizer: enabled (200 runs)");
        console.log("via_ir: enabled");
    }

    /// @notice Verify a single contract using forge verify-contract
    /// @dev Run this manually for each contract:
    ///   forge verify-contract <ADDRESS> <CONTRACT_NAME> --chain base --etherscan-api-key <API_KEY>
    function verifySingleContract() external {
        console.log("Manual verification commands:");

        console.log("");
        console.log("# TradeInfraEscrow");
        console.log("forge verify-contract \\");
        console.log("  0xea2679e443bed949206c101e2533ed1390081fe5 \\");
        console.log("  TradeInfraEscrow \\");
        console.log("  --chain base \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY");

        console.log("");
        console.log("# CentralizedTradeOracle");
        console.log("forge verify-contract \\");
        console.log("  0x951ec35799fccc3d5d42f51dbf53312146f96b4b \\");
        console.log("  CentralizedTradeOracle \\");
        console.log("  --chain base \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY");

        console.log("");
        console.log("# CredenceReceivable");
        console.log("forge verify-contract \\");
        console.log("  0x3c21bee10bef5a5d82c75496071bc813f212f63d \\");
        console.log("  CredenceReceivable \\");
        console.log("  --chain base \\");
        console.log("  --etherscan-api-key $ETHERSCAN_API_KEY");
    }
}
