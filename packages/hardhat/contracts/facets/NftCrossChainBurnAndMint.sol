// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Diamond Imports
import { ERC721Internal } from "../bases/ERC721/ERC721Internal.sol";
import { AccessControlInternal } from "../bases/AccessControl/AccessControlInternal.sol";
import { CCIPInternal } from "../bases/CCIP/CCIPInternal.sol";
import { UseStorage } from "../core/UseStorage.sol";
import { INftCrossChainBurnAndMint } from "../bases/CCNFT/INftCrossChainBurnAndMint.sol";

// CCIP Imports
import { Client } from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import { IRouterClient } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftCrossChainBurnAndMint is
	ERC721Internal,
	AccessControlInternal,
	CCIPInternal,
	UseStorage,
	INftCrossChainBurnAndMint
{
	/// @notice Pay for fees in LINK.
	/// @dev Assumes your contract has sufficient LINK to pay for CCIP fees.
	/// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
	/// @param _receiver The address of the recipient on the destination blockchain.
	///@param _tokenId The tokenId to burn and mint.
	/// @return messageId The ID of the CCIP message that was sent.
	function burnAndMintCrossChainPayLINK(
		uint64 _destinationChainSelector,
		address _receiver,
		uint256 _tokenId
	)
		external
		onlyAllowlistedDestinationChain(_destinationChainSelector)
		returns (bytes32 messageId)
	{
		// Step 1: Burn the NFT on this chain
		_burn(_tokenId);

		// Step 2: Prepare the message
		string memory functionToCall;

		functionToCall = "processCrossMintNft(address,uint256)";

		// Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
		// address(linkToken) means fees are paid in LINK
		Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
			receiver: abi.encode(_receiver),
			data: abi.encodeWithSignature(functionToCall, msg.sender, _tokenId),
			tokenAmounts: new Client.EVMTokenAmount[](0),
			extraArgs: Client._argsToBytes(
				Client.EVMExtraArgsV1({ gasLimit: 200_000 }) // Additional arguments, setting gas limit and non-strict sequency mode
			),
			feeToken: address(ccips().s_linkToken)
		});

		// Initialize a router client instance to interact with cross-chain router
		IRouterClient router = IRouterClient(_getRouter());

		// Get the fee required to send the CCIP message
		uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);

		if (fees > ccips().s_linkToken.balanceOf(address(this)))
			revert NotEnoughBalance(
				ccips().s_linkToken.balanceOf(address(this)),
				fees
			);

		// approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
		ccips().s_linkToken.approve(address(router), fees);

		// Send the message through the router and store the returned message ID
		messageId = router.ccipSend(_destinationChainSelector, evm2AnyMessage);

		// Emit an event with message details
		emit CrossChainBurnAndMintMessageSent(
			messageId,
			_destinationChainSelector,
			_receiver,
			msg.sender,
			_tokenId,
			address(ccips().s_linkToken),
			fees
		);

		// Return the message ID
		return messageId;
	}

	/// @notice Sends data to receiver on the destination chain.
	/// @dev Assumes your contract has sufficient native asset (e.g, ETH on Ethereum, MATIC on Polygon...).
	/// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
	/// @param _receiver The address of the recipient on the destination blockchain.
	/// @param _tokenId The tokenId of the NFT to be moved.
	/// @return messageId The ID of the CCIP message that was sent.
	function burnAndMintCrossChainPayNative(
		uint64 _destinationChainSelector,
		address _receiver,
		uint256 _tokenId
	)
		external
		onlyAllowlistedDestinationChain(_destinationChainSelector)
		returns (bytes32 messageId)
	{
		// Step 1: Burn the NFT on this chain
		_burn(_tokenId);

		// Step 2: Prepare the message
		string memory functionToCall;

		functionToCall = "processCrossMintNft(address,uint256)";

		Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
			receiver: abi.encode(_receiver),
			data: abi.encodeWithSignature(functionToCall, msg.sender, _tokenId),
			tokenAmounts: new Client.EVMTokenAmount[](0),
			extraArgs: Client._argsToBytes(
				Client.EVMExtraArgsV1({ gasLimit: 200_000 }) // Additional arguments, setting gas limit and non-strict sequency mode
			),
			feeToken: address(0)
		});

		uint256 fees = IRouterClient(ccips().i_router).getFee(
			_destinationChainSelector,
			evm2AnyMessage
		);

		// Initialize a router client instance to interact with cross-chain router
		IRouterClient router = IRouterClient(ccips().i_router);

		if (fees > address(this).balance)
			revert NotEnoughBalance(address(this).balance, fees);

		// Send the message through the router and store the returned message ID
		messageId = router.ccipSend{ value: fees }(
			_destinationChainSelector,
			evm2AnyMessage
		);

		emit CrossChainBurnAndMintMessageSent(
			messageId,
			_destinationChainSelector,
			_receiver,
			msg.sender,
			_tokenId,
			address(0),
			fees
		);
	}
}
