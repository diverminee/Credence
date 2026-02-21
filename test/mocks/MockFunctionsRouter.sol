// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Minimal mock of IFunctionsRouter for testing ChainlinkTradeOracle
contract MockFunctionsRouter {
    uint256 private _requestCounter;

    /// @notice Records the last request for test assertions
    bytes32 public lastRequestId;
    bytes public lastData;

    /// @notice Simulates IFunctionsRouter.sendRequest
    function sendRequest(uint64, bytes calldata data, uint16, uint32, bytes32) external returns (bytes32 requestId) {
        _requestCounter++;
        requestId = keccak256(abi.encodePacked(_requestCounter, block.timestamp));
        lastRequestId = requestId;
        lastData = data;
    }

    /// @notice Helper to call handleOracleFulfillment on the client (simulates DON callback)
    function fulfillRequest(address client, bytes32 requestId, bytes memory response, bytes memory err) external {
        // Call handleOracleFulfillment which is the entry point FunctionsClient exposes
        (bool success,) = client.call(
            abi.encodeWithSignature("handleOracleFulfillment(bytes32,bytes,bytes)", requestId, response, err)
        );
        require(success, "fulfillRequest call failed");
    }
}
