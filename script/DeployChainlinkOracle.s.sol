// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ChainlinkTradeOracle} from "../src/ChainlinkTradeOracle.sol";

/// @title Deploy ChainlinkTradeOracle
/// @notice Foundry script for testnet/mainnet deployment of the Chainlink Functions oracle
///
/// Required environment variables:
///   CHAINLINK_ROUTER       - Chainlink Functions router address (e.g., Sepolia: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0)
///   CHAINLINK_SUB_ID       - Chainlink Functions subscription ID (uint64)
///   CHAINLINK_DON_ID       - Chainlink Functions DON ID (bytes32, e.g., 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000)
///   CHAINLINK_CALLBACK_GAS - Callback gas limit (uint32, e.g., 300000)
///
/// Optional environment variables:
///   CHAINLINK_JS_SOURCE    - JavaScript source code (defaults to a sample shipping API check)
///
/// Usage:
///   forge script script/DeployChainlinkOracle.s.sol --rpc-url $RPC_URL --broadcast --verify
contract DeployChainlinkOracle is Script {
    // Default JS source: queries a shipping status API endpoint
    string internal constant DEFAULT_JS_SOURCE = "const tracking = args[0];"
        "const apiUrl = `https://api.example.com/v1/shipments/${tracking}/status`;"
        "const res = await Functions.makeHttpRequest({ url: apiUrl });"
        "if (res.error) { throw Error('API request failed'); }" "const delivered = res.data.status === 'delivered';"
        "return Functions.encodeUint256(delivered ? 1 : 0);";

    function run() external {
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

        vm.startBroadcast();
        ChainlinkTradeOracle oracle = new ChainlinkTradeOracle(router, subId, donId, callbackGas, jsSource);
        vm.stopBroadcast();

        console.log("ChainlinkTradeOracle deployed at:", address(oracle));
        console.log("  Router:", router);
        console.log("  Subscription ID:", subId);
        console.log("  Callback Gas:", callbackGas);
    }
}
