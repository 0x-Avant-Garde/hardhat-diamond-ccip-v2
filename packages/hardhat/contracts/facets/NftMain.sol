// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC721Internal } from "../bases/ERC721/ERC721Internal.sol";
import { AccessControlInternal } from "../bases/AccessControl/AccessControlInternal.sol";
import { UseStorage } from "../core/UseStorage.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract NftMain is ERC721Internal, AccessControlInternal, UseStorage {
	using Strings for uint256;

	function mint(uint256 tokenId, address to) external {
		_safeMint(to, tokenId);
	}

	function burn(uint256 tokenId) external {
		_burn(tokenId);
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(
		uint256 tokenId
	) external virtual returns (string memory) {
		_requireOwned(tokenId);

		string memory baseURI = ccnfts().baseURI;
		return
			bytes(baseURI).length > 0
				? string.concat(baseURI, tokenId.toString())
				: "";
	}

	function setCubesURI(
		string memory _newURI
	) external onlyRole(OPERATOR_ROLE) {
		ccnfts().baseURI = _newURI;
	}
}
