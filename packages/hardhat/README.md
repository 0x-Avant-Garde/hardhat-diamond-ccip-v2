# Diamond-Hardhat-CCIP

An open-source boilerplate for how to use CCIP integrations with [ERC-2535 DIamond Pattern](https://eips.ethereum.org/EIPS/eip-2535) built with [Scaffod-Eth 2](https://scaffoldeth.io) and [hardhat-deploy](https://github.com/wighawag/hardhat-deploy).

### _**This code is unaudited and for proof of concept purposes only. Do not use this code directly in production. This code does not account for the same NFT being minted on multiple chains which is outside the scope of this boilerplate, and ensuring that is a complex task you will need to implement on your own.**_

## Requirements

Before you begin, you need to install the following tools:

- [Node (v18 LTS or later)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

Recommended:
A general understanding of the Diamond Pattern. This is a really good [guide](https://medium.com/@dumbnamenumbers/a-step-by-step-guide-to-using-the-diamond-standard-eip-2535-to-create-and-upgrade-an-nft-mar-b4093a46b818) to understand the basics and core concepts used in this project.

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Clone this repo & install dependencies

```
git clone https://github.com/0x-Avant-Garde/hardhat-diamond-ccip.git
cd hardhat-diamond-ccip
yarn install
```

If you get yarn errors during installation, you may need to run:

`yarn set version stable`

2. Run the tests to ensure everything is setup properly.

```
yarn test
```

3. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Hardhat. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `hardhat.config.ts`.

4. On a second terminal, deploy the test contract:

```
yarn deploy
```

This command deploys a test smart contract to the local network. The contract is located in `packages/hardhat/contracts` and can be modified to suit your needs. The `yarn deploy` command uses the deploy script located in `packages/hardhat/deploy` to deploy the contract to the network. You can also customize the deploy script.

5. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contract using the `Debug Contracts` page. You can tweak the app config in `packages/nextjs/scaffold.config.ts`.

- Edit your smart contracts in `packages/hardhat/contracts`
- Edit your frontend in `packages/nextjs/pages`
- Edit your deployment scripts in `packages/hardhat/deploy`

## Deploying and Testing Cross Chain

Be sure to set your .env variables for at least `DPK` (short for DEPLOYER_PRIVATE_KEY) and `MUMBAI_API_KEY` (you need this to verify on polygonscan).

You need to get:

[Test Avax](https://core.app/tools/testnet-faucet/?subnet=c&token=c) - At least 0.5

[Test MATIC](https://faucet.quicknode.com/polygon/mumbai/) - at least 0.5

[Test LINK on Fuji](https://faucets.chain.link/fuji)

[Test LINK on Mumbai](https://faucets.chain.link/mumbai) - optional if you want to run the test in reverse.

### Deploy and Verify the Contracts

To Deploy the contracts run:

```ts
yarn deployCCIP --reset
```

The `--reset` flag is to clear the deployments folder if you want to start fresh.

-To Verify the contracts run:

```ts
yarn verify --network avaxFuji

yarn verify --network polygonMumbai
```

### Testing Cross Chain Mints

**Before you run this script, ensure you replace your contract address in the file to your contract address.**

Navigate to the `/packages/hardhat` folder and run

```ts
npx hardhat run interactions/00_CrossChainMint.ts
```

This script does the following steps:

1. Sends 5 LINK to the AVAX Contract to pay fees. (You only need to do this once for testing purposes)
2. Allows Polygon Mumbai as a Destination Chain.
3. Allows Avax Fuji as a Source Chain.
4. Allows the Avax Fuji Contract address as a Sender (note the address is the same on both chains).
5. Mints a NFT from Avax Fuji with `tokenId: 1` to `msg.sender` on Polygon Mumbai.

## Understanding the Facets

The facets are separated into 2 categories: Shared and Custom. They can be found in `packages/hardhat/contracts/facets`.

### Shared Facets

1. AccessControlFacet
   - This facet is based off of the [OpenZeppelin AccessControlUpgradeable Contract](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/access/AccessControlUpgradeable.sol)
   - It has been modified to conform to the Diamond Pattern but has all of the same functionality.
2. CCIPFacet
   - This facet is primarily based off of the CCIP [ProgrammableDefensiveTokenTransfers Example](https://docs.chain.link/ccip/tutorials/programmable-token-transfers-defensive).
3. DiamondCutFacet
   - This is the main entry-point to the Diamond. It is customized from the default Diamond.sol to add Access Control functionality
4. ERC721Facet
   - This facet is based off of the [Openzeppelin ERC721Upgradeable Contract](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC721/ERC721Upgradeable.sol)
   - It has been modified to conform to the Diamond Pattern but has all of the same functionality.
5. SharedDiamondInitFacet
   - This facet is used to initialize the contract on deployment.
   - it takes the following arguments to set the initial state
   ```ts
   function init(
     	string memory _name,
     	string memory _symbol,
     	string memory _baseURI,
     	address _router,  // Router address for the chain you are deploying to
     	address _linkTokenAddress  // Link token address for the chain you are deploying to
     ) external onlyRole(DEFAULT_ADMIN_ROLE)
   ```
   - Notice the onlyRole() modifier which ensures that only the person who deployed the Diamond can run the init function.
   - This facet also handles all of the `supportedInterface` initializations.
6. UseStorage (found in the `/packages/hardhat/contracts/core` folder)
   - This Facet facilitates a centralized location to provide easy access to the different storage locations in other Facets.
   - It has a RootStorage struct that only tracks if the initialization has been run yet or not.
7. Diamond (found in the `/packages/hardhat/contracts/core` folder)
   - This facet is where the fallback() function is that directs the incoming calls to the proper facets. **This is also where the initial roles are granted for Access Control**

### Custom Facets

1. NftCrossChainBurnAndMint

   This facet has 2 functions.
   The first one allows you to burn your NFT from the current chain and mint it on the destination chain, paying with LINK tokens.

   ```ts
   function burnAndMintCrossChainPayLINK(
   	uint64 _destinationChainSelector,
   	address _receiver,
   	uint256 _tokenId
   )
   	external
   	onlyAllowlistedDestinationChain(_destinationChainSelector)
   	returns (bytes32 messageId)
   ```

   The second allows you to do the same and pay with Native token.

   ````ts
     function burnAndMintCrossChainPayNative(
   	uint64 _destinationChainSelector,
   	address _receiver,
   	uint256 _tokenId
   )
   	external
   	onlyAllowlistedDestinationChain(_destinationChainSelector)
   	returns (bytes32 messageId)```
   ````

2. NftCrossChainMinter

   This facet has 3 functions. The first allows you to mint a NFT from the source chain to the destination chain, paying in LINK.

   ```ts
   function mintCrossChainPayLINK(
   	uint64 _destinationChainSelector,
   	address _receiver,
   	uint256 _tokenId
   )
   	external
   	onlyAllowlistedDestinationChain(_destinationChainSelector)
   	returns (bytes32 messageId)
   ```

   The second allows you to mint a NFT from the source chain to the destination chain, paying in Native tokens.

   ```ts
   function mintCrossChainPayNative(
   	uint64 _destinationChainSelector,
   	address _receiver,
   	uint256 _tokenId
   )
   	external
   	onlyAllowlistedDestinationChain(_destinationChainSelector)
   	returns (bytes32 messageId)
   ```

   The third is the function that is called by \_ccipReceive() when messages from other chains arrive.

   ```ts
   	function processCrossMintNft(
   	address _to,
   	uint256 _tokenId
   ) external onlySelf {
   	_safeMint(_to, _tokenId);
   }
   ```

3. NftCrossChainReceiver

   This contract is the main Receiver entry point for incoming messages from the Router. The primary function is:

   ```ts
   function ccipReceive(
   	Client.Any2EVMMessage calldata any2EvmMessage
   )
   	external
   	onlyRouter
   	onlyAllowlisted(
   		any2EvmMessage.sourceChainSelector,
   		abi.decode(any2EvmMessage.sender, (address))
   	)
   ```

4. NftMain

   This is the generic NFT facet that allows for simple Mints, Burns, and handles the URI logic.

## Understanding Bases and Core

These folders contain the logic for the Internal, Storage, and Interface logic for each Facet.

The contracts are broken up into these different smaller contracts in order to make it easier to share logic between facets. Internal functions are only deployed if they are used.

## Diamond Storage

Each Storage library consists of 3 main parts

The first part definest the storage position

```ts
	bytes32 constant ERC721_STORAGE_POSITION =
		keccak256("openzeppelin.erc721.storage");
```

The second part is the Storage Struct containing the variables related to that facet. This ensures the storage slot is filled with exactly one thing.

```ts
	struct ERC721StorageStruct {
		string _name;
		string _symbol;
		mapping(uint256 tokenId => address) _owners;
		mapping(address owner => uint256) _balances;
		mapping(uint256 tokenId => address) _tokenApprovals;
		mapping(address owner => mapping(address operator => bool)) _operatorApprovals;
	}
```

The last part is the function that is called to easily retrieve the storage slot.

```ts
	function _getERC721Storage()
		internal
		pure
		returns (ERC721StorageStruct storage $)
	{
		bytes32 position = ERC721_STORAGE_POSITION;
		assembly {
			$.slot := position
		}
    }
```

## Proxy and Testing Folders

These are there in case you want to use a different type of proxy, and the Mock Token can be used to easily bootstrap a mock payment token to mint the NFTs or anything else.

## Questions related to Scaffold-Eth 2

A comprehensive guide on how to use this can be found in the root README.md
