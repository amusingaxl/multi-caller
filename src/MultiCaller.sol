pragma solidity ^0.8.17;

/**
 * @title MultiCaller
 * @notice Batches transactions or calls for execution.
 * @dev This contract has no storage, which means it is safe to be used as a target for `delegatecall`.
 * @author @amusingaxl
 */
contract MultiCaller {
    /**
     * @notice Contains all required information to perform a `call`.
     * @param target The conrtract to be called.
     * @param data The calldata-encoded payload.
     */
    struct Call {
        address target;
        bytes data;
    }

    /**
     * @notice Contains all required information to perform a payable `call`.
     * @param target The conrtract to be called.
     * @param data The calldata-encoded payload.
     * @param value The value in `wei` to be send with the call.
     */
    struct PayableCall {
        address target;
        bytes data;
        uint256 value;
    }

    /**
     * @notice Revert reason when a multi-call fails.
     * @param reason The reason provided by the target contract, if any.
     */
    error CallReverted(bytes reason);

    /**
     * @notice Executes all transactions sequentially.
     * @dev Any failing transactions are ignored.
     * @param calls A list of calls to make.
     */
    function multiSend(Call[] calldata calls) external {
        for (uint256 i; i < calls.length; ) {
            calls[i].target.call(calls[i].data);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Enforces the execution all transactions sequentially.
     * @dev A single failing transaction causes the entire call to revert.
     * @param calls A list of calls to make.
     */
    function atomicMultiSend(Call[] calldata calls) external {
        for (uint256 i; i < calls.length; ) {
            (bool ok, bytes memory result) = calls[i].target.call(calls[i].data);
            if (!ok) {
                revert CallReverted(result);
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Executes all payable transactions sequentially.
     * @dev Any failing transactions are ignored.
     * Transactions could fail for a variety of reasons, such as:
     *     - gas limit exceeded
     *     - not enough funds (i.e.: `msg.value` does not cover for the total value sent by the calls)
     *     - revert/error in the target contract
     * @param calls A list of calls to make.
     */
    function multiSend(PayableCall[] calldata calls) external payable {
        for (uint256 i; i < calls.length; ) {
            calls[i].target.call{value: calls[i].value}(calls[i].data);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Executes all payable transactions sequentially.
     * @dev A single failing transaction causes the entire call to revert.
     * Transactions could fail for a variety of reasons, such as:
     *     - gas limit exceeded
     *     - not enough funds (i.e.: `msg.value` does not cover for the total value sent by the calls)
     *     - revert/error in the target contract
     * @param calls A list of calls to make.
     */
    function atomicMultiSend(PayableCall[] calldata calls) external payable {
        for (uint256 i; i < calls.length; ) {
            (bool ok, bytes memory result ) = calls[i].target.call{value: calls[i].value}(calls[i].data);
            if (!ok) {
                revert CallReverted(result);
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Returns the result of all calls sequentially.
     * @dev Failed calls will have the revert reason instead of the return value in the results.
     * @param calls A list of calls to make.
     * @return The list of return values for all calls.
     */
    function multiCall(Call[] calldata calls) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](calls.length);

        for (uint256 i; i < calls.length; ) {
            (, bytes memory result) = calls[i].target.staticcall(calls[i].data);
            results[i] = result;

            unchecked {
                i++;
            }
        }

        return results;
    }

    /**
     * @notice Returns the result of all calls sequentially.
     * @dev A single failing call causes the entire call to revert.
     * @param calls A list of calls to make.
     * @return The list of return values for all calls.
     */
    function atomicMultiCall(Call[] calldata calls) external view returns (bytes[] memory) {
        bytes[] memory results = new bytes[](calls.length);

        for (uint256 i; i < calls.length; ) {
            (bool ok, bytes memory result) = calls[i].target.staticcall(calls[i].data);
            if (!ok) {
                revert CallReverted(result);
            }
            results[i] = result;

            unchecked {
                i++;
            }
        }

        return results;
    }
}
