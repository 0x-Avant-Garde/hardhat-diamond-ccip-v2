// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC721Internal } from "../bases/ERC721/ERC721Internal.sol";
import { AccessControlInternal } from "../bases/AccessControl/AccessControlInternal.sol";
import { CCIPInternal } from "../bases/CCIP/CCIPInternal.sol";
import { UseStorage } from "../core/UseStorage.sol";
import { INftCrossChainReceiver } from "../bases/CCNFT/INftCrossChainReceiver.sol";

//CCIP Imports
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { EnumerableMap } from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/utils/structs/EnumerableMap.sol";
import { IERC20 } from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

contract NftCrossChainReceiver is
	ERC721Internal,
	AccessControlInternal,
	CCIPInternal,
	UseStorage,
	INftCrossChainReceiver
{
	using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
	using SafeERC20 for IERC20;

	function _ccipReceive(
		Client.Any2EVMMessage memory message
	) internal override {
		(bool success, ) = address(this).call(message.data);
		require(success);
		emit MintCallSuccessfull();
	}

	/// @notice The entrypoint for the CCIP router to call. This function should
	/// never revert, all errors should be handled internally in this contract.
	/// @param any2EvmMessage The message to process.
	/// @dev Extremely important to ensure only router calls this.
	function ccipReceive(
		Client.Any2EVMMessage calldata any2EvmMessage
	)
		external
		onlyRouter
		onlyAllowlisted(
			any2EvmMessage.sourceChainSelector,
			abi.decode(any2EvmMessage.sender, (address))
		) // Make sure the source chain and sender are allowlisted
	{
		/* solhint-disable no-empty-blocks */
		try this.processMessage(any2EvmMessage) {
			// Intentionally empty in this example; no action needed if processMessage succeeds
		} catch (bytes memory err) {
			// Could set different error codes based on the caught error. Each could be
			// handled differently.
			ccips().s_failedMessages.set(
				any2EvmMessage.messageId,
				uint256(ErrorCode.BASIC)
			);
			ccips().s_messageContents[
				any2EvmMessage.messageId
			] = any2EvmMessage;
			// Don't revert so CCIP doesn't revert. Emit event instead.
			// The message can be retried later without having to do manual execution of CCIP.
			emit MessageFailed(any2EvmMessage.messageId, err);
			return;
		}
	}

	/// @notice Serves as the entry point for this contract to process incoming messages.
	/// @param any2EvmMessage Received CCIP message.
	/// @dev Transfers specified token amounts to the owner of this contract. This function
	/// must be external because of the  try/catch for error handling.
	/// It uses the `onlySelf`: can only be called from the contract.
	function processMessage(
		Client.Any2EVMMessage calldata any2EvmMessage
	)
		external
		onlySelf
		onlyAllowlisted(
			any2EvmMessage.sourceChainSelector,
			abi.decode(any2EvmMessage.sender, (address))
		) // Make sure the source chain and sender are allowlisted
	{
		_ccipReceive(any2EvmMessage); // process the message - may revert as well
	}
}
