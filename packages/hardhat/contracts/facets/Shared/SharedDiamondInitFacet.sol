// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IDiamondCut } from "../../core/IDiamondCut.sol";
import { IDiamondLoupe } from "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { IERC721, IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC5267 } from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import { AccessControlInternal } from "../..//bases/AccessControl/AccessControlInternal.sol";
import { LibDiamond } from "../../core/LibDiamond.sol";
import { UseStorage } from "../../core/UseStorage.sol";
import { IAny2EVMMessageReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";

contract SharedDiamondInitFacet is AccessControlInternal, UseStorage {
	function init(
		string memory _name,
		string memory _symbol,
		string memory _baseURI,
		address _router,
		address _linkTokenAddress
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		if (rs().isInitialized) return;

		// Set up ERC721
		erc721s()._name = _name;
		erc721s()._symbol = _symbol;

		// Set up NFT
		ccnfts().baseURI = _baseURI;

		ccips().i_router = _router;
		ccips().s_linkToken = IERC20(_linkTokenAddress);

		ds().supportedInterfaces[type(IERC165).interfaceId] = true;
		ds().supportedInterfaces[type(IDiamondCut).interfaceId] = true;
		ds().supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
		ds().supportedInterfaces[type(IERC173).interfaceId] = true;
		ds().supportedInterfaces[type(IERC721).interfaceId] = true;
		ds().supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		ds().supportedInterfaces[type(IAccessControl).interfaceId] = true;
		ds().supportedInterfaces[type(IERC5267).interfaceId] = true;
		ds().supportedInterfaces[
			type(IAny2EVMMessageReceiver).interfaceId
		] = true;

		rs().isInitialized = true;
	}
}
