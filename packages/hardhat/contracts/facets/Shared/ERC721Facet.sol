// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// OZ Imports
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// Modified
import { ERC721Internal } from "../../bases/ERC721/ERC721Internal.sol";
import { UseStorage } from "../../core/UseStorage.sol";

contract ERC721Facet is ERC721Internal, UseStorage {
	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) external view returns (uint256) {
		if (owner == address(0)) {
			revert ERC721InvalidOwner(address(0));
		}
		return erc721s()._balances[owner];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) external view returns (address) {
		return _requireOwned(tokenId);
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() external view returns (string memory) {
		return erc721s()._name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() external view returns (string memory) {
		return erc721s()._symbol;
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) external {
		_approve(to, tokenId, msg.sender);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) external view returns (address) {
		_requireOwned(tokenId);

		return _getApproved(tokenId);
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) external {
		_setApprovalForAll(msg.sender, operator, approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(
		address owner,
		address operator
	) external view returns (bool) {
		return erc721s()._operatorApprovals[owner][operator];
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(address from, address to, uint256 tokenId) public {
		if (to == address(0)) {
			revert ERC721InvalidReceiver(address(0));
		}
		// Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
		// (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
		address previousOwner = _update(to, tokenId, msg.sender);
		if (previousOwner != from) {
			revert ERC721IncorrectOwner(from, tokenId, previousOwner);
		}
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public {
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public {
		transferFrom(from, to, tokenId);
		_checkOnERC721Received(from, to, tokenId, data);
	}
}
