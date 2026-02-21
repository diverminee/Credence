// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {TradeInfraEscrow} from "../src/core/TradeInfraEscrow.sol";
import {CentralizedTradeOracle} from "../src/CentralizedTradeOracle.sol";
import {ChainlinkTradeOracle} from "../src/ChainlinkTradeOracle.sol";
import {CredenceReceivable} from "../src/CredenceReceivable.sol";
import {ProtocolArbiterMultisig} from "../src/governance/ProtocolArbiterMultisig.sol";
import {EscrowTypes} from "../src/libraries/EscrowTypes.sol";
import {ITradeOracle} from "../src/interfaces/ITradeOracle.sol";

/// @title Deploy Credence Escrow System
/// @notice Full deployment of oracle, escrow, receivable NFT, and multisig arbiter.
///         Supports both CentralizedTradeOracle (local/testnet) and ChainlinkTradeOracle (mainnet).
///
/// @dev Environment variables:
///   PRIVATE_KEY               - Deployer private key (defaults to Anvil key #0)
///   FEE_RECIPIENT             - Fee recipient address (defaults to Anvil #1)
///   PROTOCOL_ARBITER          - Protocol arbiter EOA (defaults to Anvil #2; overridden by multisig if deployed)
///   ORACLE_OWNER              - Oracle owner for CentralizedTradeOracle (defaults to deployer)
///   USDC_ADDRESS              - USDC token address (defaults to Sepolia)
///   USDT_ADDRESS              - USDT token address (defaults to Sepolia)
///   USE_CHAINLINK_ORACLE      - Set "true" to deploy ChainlinkTradeOracle instead of centralized
///   CHAINLINK_ROUTER          - Chainlink Functions router (required if USE_CHAINLINK_ORACLE=true)
///   CHAINLINK_SUB_ID          - Chainlink subscription ID (required if USE_CHAINLINK_ORACLE=true)
///   CHAINLINK_DON_ID          - Chainlink DON ID (required if USE_CHAINLINK_ORACLE=true)
///   CHAINLINK_CALLBACK_GAS    - Chainlink callback gas limit (required if USE_CHAINLINK_ORACLE=true)
///   CHAINLINK_JS_SOURCE       - Custom JS source (optional, has default)
///   MULTISIG_SIGNERS          - Comma-separated signer addresses (empty = skip multisig deploy)
///   MULTISIG_THRESHOLD        - Minimum approvals required (defaults to 2)
///   DEPLOYMENT_TIER           - TESTNET | LAUNCH | GROWTH | MATURE (defaults to TESTNET)
contract DeployCredence is Script {
    // ── Sepolia testnet token addresses (override via env for other networks) ──
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant SEPOLIA_USDT = 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06;

    // Default Chainlink JS source for shipping verification
    string internal constant DEFAULT_JS_SOURCE = "const tracking = args[0];"
        "const apiUrl = `https://api.example.com/v1/shipments/${tracking}/status`;"
        "const res = await Functions.makeHttpRequest({ url: apiUrl });"
        "if (res.error) { throw Error('API request failed'); }" "const delivered = res.data.status === 'delivered';"
        "return Functions.encodeUint256(delivered ? 1 : 0);";

    // Deployed addresses (populated after run(), readable by tests)
    address public deployedOracle;
    address public deployedEscrow;
    address public deployedReceivable;
    address public deployedMultisig;

    function run() external {
        // ── Configuration ──────────────────────────────────────
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) // Anvil default key #0
        );

        address deployerAddress = vm.addr(deployerPrivateKey);

        address feeRecipient = vm.envOr(
            "FEE_RECIPIENT",
            address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8) // Anvil default #1
        );

        address protocolArbiter = vm.envOr(
            "PROTOCOL_ARBITER",
            address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC) // Anvil default #2
        );

        address oracleOwner = vm.envOr("ORACLE_OWNER", deployerAddress);

        address usdcAddress = vm.envOr("USDC_ADDRESS", SEPOLIA_USDC);
        address usdtAddress = vm.envOr("USDT_ADDRESS", SEPOLIA_USDT);

        bool useChainlink = vm.envOr("USE_CHAINLINK_ORACLE", false);

        string memory deploymentTierStr = vm.envOr("DEPLOYMENT_TIER", string("TESTNET"));

        // ── Deploy ─────────────────────────────────────────────
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Oracle (centralized or Chainlink)
        address oracleAddr;
        if (useChainlink) {
            address router = vm.envAddress("CHAINLINK_ROUTER");
            uint64 subId = uint64(vm.envUint("CHAINLINK_SUB_ID"));
            bytes32 donId = vm.envBytes32("CHAINLINK_DON_ID");
            uint32 callbackGas = uint32(vm.envUint("CHAINLINK_CALLBACK_GAS"));

            string memory jsSource = DEFAULT_JS_SOURCE;
            try vm.envString("CHAINLINK_JS_SOURCE") returns (string memory custom) {
                if (bytes(custom).length > 0) {
                    jsSource = custom;
                }
            } catch {}

            ChainlinkTradeOracle chainlinkOracle = new ChainlinkTradeOracle(router, subId, donId, callbackGas, jsSource);
            oracleAddr = address(chainlinkOracle);
            console.log("ChainlinkTradeOracle deployed at:", oracleAddr);
        } else {
            CentralizedTradeOracle centralOracle = new CentralizedTradeOracle(oracleOwner);
            oracleAddr = address(centralOracle);
            console.log("CentralizedTradeOracle deployed at:", oracleAddr);
        }

        // 2. Deploy TradeInfraEscrow
        TradeInfraEscrow escrow = new TradeInfraEscrow(oracleAddr, feeRecipient, protocolArbiter);
        console.log("TradeInfraEscrow deployed at:", address(escrow));

        // 3. Deploy CredenceReceivable and register with escrow
        CredenceReceivable receivable = new CredenceReceivable(address(escrow));
        escrow.setReceivableMinter(address(receivable));
        console.log("CredenceReceivable deployed at:", address(receivable));

        // 4. Seed the recommended token list: ETH (address(0)), USDC, USDT
        escrow.addApprovedToken(address(0)); // Native ETH
        escrow.addApprovedToken(usdcAddress);
        escrow.addApprovedToken(usdtAddress);
        console.log("Approved tokens seeded: ETH, USDC, USDT");

        // 5. Set deployment tier if not TESTNET
        EscrowTypes.DeploymentTier tier = _parseTier(deploymentTierStr);
        if (tier != EscrowTypes.DeploymentTier.TESTNET) {
            escrow.upgradeTier(tier);
            console.log("Deployment tier set to:", deploymentTierStr);
        }

        // 6. Deploy ProtocolArbiterMultisig if signers are configured
        address multisigAddr = address(0);
        string memory signersStr = vm.envOr("MULTISIG_SIGNERS", string(""));
        if (bytes(signersStr).length > 0) {
            address[] memory signers = _parseSigners(signersStr);
            uint256 multisigThreshold = vm.envOr("MULTISIG_THRESHOLD", uint256(2));

            ProtocolArbiterMultisig multisig = new ProtocolArbiterMultisig(address(escrow), signers, multisigThreshold);
            multisigAddr = address(multisig);
            console.log("ProtocolArbiterMultisig deployed at:", multisigAddr);
            console.log("  Signers:", signers.length, "Threshold:", multisigThreshold);
        }

        vm.stopBroadcast();

        // Store deployed addresses for test accessibility
        deployedOracle = oracleAddr;
        deployedEscrow = address(escrow);
        deployedReceivable = address(receivable);
        deployedMultisig = multisigAddr;

        // ── Post-Deploy Assertions ───────────────────────────
        _runPostDeployChecks(
            escrow,
            oracleAddr,
            feeRecipient,
            protocolArbiter,
            address(receivable),
            usdcAddress,
            usdtAddress,
            deployerAddress
        );

        // ── Deployment Summary ───────────────────────────────
        console.log("\n=== Deployment Summary ===");
        console.log("Oracle:            ", oracleAddr);
        if (!useChainlink) {
            console.log("Oracle Owner:      ", oracleOwner);
        }
        console.log("Escrow:            ", address(escrow));
        console.log("Escrow Owner:      ", deployerAddress);
        console.log("Fee Recipient:     ", feeRecipient);
        console.log("Protocol Arbiter:  ", protocolArbiter);
        console.log("Receivable NFT:    ", address(receivable));
        if (multisigAddr != address(0)) {
            console.log("Multisig:          ", multisigAddr);
        }
        console.log("Deployment Tier:   ", deploymentTierStr);
        console.log("Max Escrow Amount: ", escrow.maxEscrowAmount());
        console.log("Approved USDC:     ", usdcAddress);
        console.log("Approved USDT:     ", usdtAddress);
        console.log("==========================\n");

        // ── Write .env.deployed ──────────────────────────────
        string memory envContent = string.concat(
            "# Credence Deployment Output\n",
            "# Generated by DeployCredence.s.sol\n\n",
            "ORACLE_ADDRESS=",
            vm.toString(oracleAddr),
            "\n",
            "ESCROW_ADDRESS=",
            vm.toString(address(escrow)),
            "\n",
            "RECEIVABLE_ADDRESS=",
            vm.toString(address(receivable)),
            "\n"
        );

        if (multisigAddr != address(0)) {
            envContent = string.concat(envContent, "MULTISIG_ADDRESS=", vm.toString(multisigAddr), "\n");
        }

        envContent = string.concat(
            envContent,
            "FEE_RECIPIENT=",
            vm.toString(feeRecipient),
            "\n",
            "PROTOCOL_ARBITER=",
            vm.toString(protocolArbiter),
            "\n",
            "DEPLOYMENT_TIER=",
            deploymentTierStr,
            "\n"
        );

        vm.writeFile(".env.deployed", envContent);
        console.log("Deployment addresses written to .env.deployed");
    }

    // ── Internal Helpers ─────────────────────────────────────

    /// @notice Parse deployment tier string to enum
    /// @param tierStr String representation of tier (TESTNET, LAUNCH, GROWTH, MATURE)
    /// @return tier The corresponding DeploymentTier enum value
    function _parseTier(string memory tierStr) internal pure returns (EscrowTypes.DeploymentTier) {
        bytes32 h = keccak256(bytes(tierStr));
        if (h == keccak256("LAUNCH")) return EscrowTypes.DeploymentTier.LAUNCH;
        if (h == keccak256("GROWTH")) return EscrowTypes.DeploymentTier.GROWTH;
        if (h == keccak256("MATURE")) return EscrowTypes.DeploymentTier.MATURE;
        return EscrowTypes.DeploymentTier.TESTNET; // default
    }

    /// @notice Parse comma-separated address string into array
    /// @param signersCsv Comma-separated signer addresses (e.g., "0xA,0xB,0xC")
    /// @return signers Array of parsed addresses
    function _parseSigners(string memory signersCsv) internal pure returns (address[] memory) {
        // Count commas to determine array size
        bytes memory b = bytes(signersCsv);
        uint256 count = 1;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == ",") count++;
        }

        address[] memory signers = new address[](count);
        uint256 start = 0;
        uint256 idx = 0;

        for (uint256 i = 0; i <= b.length; i++) {
            if (i == b.length || b[i] == ",") {
                // Extract substring [start, i)
                bytes memory segment = new bytes(i - start);
                for (uint256 j = start; j < i; j++) {
                    segment[j - start] = b[j];
                }
                signers[idx] = _parseAddress(string(segment));
                idx++;
                start = i + 1;
            }
        }

        return signers;
    }

    /// @notice Parse hex address string to address
    /// @param addrStr Hex address string (with or without 0x prefix)
    /// @return addr The parsed address
    function _parseAddress(string memory addrStr) internal pure returns (address) {
        bytes memory b = bytes(addrStr);

        // Strip leading whitespace
        uint256 start = 0;
        while (start < b.length && (b[start] == " " || b[start] == "\t")) {
            start++;
        }

        // Strip trailing whitespace
        uint256 end = b.length;
        while (end > start && (b[end - 1] == " " || b[end - 1] == "\t")) {
            end--;
        }

        // Skip 0x prefix
        if (end - start >= 2 && b[start] == "0" && (b[start + 1] == "x" || b[start + 1] == "X")) {
            start += 2;
        }

        uint256 result = 0;
        for (uint256 i = start; i < end; i++) {
            result = result * 16;
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result += c - 48; // 0-9
            } else if (c >= 65 && c <= 70) {
                result += c - 55; // A-F
            } else if (c >= 97 && c <= 102) {
                result += c - 87; // a-f
            }
        }
        return address(uint160(result));
    }

    /// @notice Run post-deploy assertions to verify deployment correctness
    /// @param escrow The deployed escrow contract
    /// @param oracleAddr Expected oracle address
    /// @param feeRecip Expected fee recipient
    /// @param arbiter Expected protocol arbiter
    /// @param receivableAddr Expected receivable minter address
    /// @param usdc Expected USDC address
    /// @param usdt Expected USDT address
    /// @param deployer Expected owner address
    function _runPostDeployChecks(
        TradeInfraEscrow escrow,
        address oracleAddr,
        address feeRecip,
        address arbiter,
        address receivableAddr,
        address usdc,
        address usdt,
        address deployer
    ) internal view {
        require(address(escrow.oracle()) == oracleAddr, "Oracle address mismatch");
        require(escrow.feeRecipient() == feeRecip, "Fee recipient mismatch");
        require(escrow.protocolArbiter() == arbiter, "Protocol arbiter mismatch");
        require(escrow.receivableMinter() == receivableAddr, "Receivable minter not registered");
        require(escrow.approvedTokens(address(0)), "ETH not in token allowlist");
        require(escrow.approvedTokens(usdc), "USDC not in token allowlist");
        require(escrow.approvedTokens(usdt), "USDT not in token allowlist");
        require(escrow.owner() == deployer, "Deployer is not owner");
        console.log("All post-deploy checks passed");
    }
}
