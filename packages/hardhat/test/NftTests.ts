import { deployments } from "hardhat";
import { BigNumberish, ZeroAddress, solidityPackedKeccak256 } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
const setupTest = deployments.createFixture(async ({ deployments, getNamedAccounts, ethers }, options) => {
  await deployments.fixture(); // ensure you start from a fresh deployments
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const { diamond } = deployments;

  const ccipDiamond = await diamond.deploy("CCIPDiamond", {
    from: deployer.address,
    autoMine: true,
    log: true,
    waitConfirmations: 1,
    defaultOwnershipFacet: false,
    defaultCutFacet: false,
    diamondContract: "Diamond",

    // diamondContractArgs: [deployer, [], ""],
    // owner: deployer,
    // excludeSelectors: { [""]: [FunctionFragment.getSelector("")] },

    facets: [
      { name: "SharedDiamondInitFacet" },
      { name: "AccessControlFacet" },
      { name: "DiamondCutFacet" },
      { name: "ERC721Facet" },
      { name: "CCIPFacet" },
      { name: "NftMain" },
      { name: "NftCrossChainBurnAndMint" },
      { name: "NftCrossChainMinter" },
      { name: "NftCrossChainReceiver" },
    ],

    execute: {
      contract: "SharedDiamondInitFacet",
      methodName: "init",
      args: [
        "CCNft",
        "CCNFT",
        "ipfs://yourUri",
        ZeroAddress, // router
        ZeroAddress, // link
      ],
    },
  });

  const nftMainInstance = await ethers.getContractAt("NftMain", ccipDiamond.address, deployer);
  const erc721Instance = await ethers.getContractAt("ERC721Facet", ccipDiamond.address, deployer);

  return {
    deployer,
    nftMainInstance,
    erc721Instance,
  };
});
describe("Nft Tests", function () {
  it("Should mint a nft on the current chain", async function () {
    const { deployer, nftMainInstance, erc721Instance } = await setupTest();

    await nftMainInstance.mint(1, deployer.address);

    expect(await erc721Instance.ownerOf(1)).to.equal(deployer.address);
  });

  it("Should mint and then burn a nft on the current chain", async function () {
    const { deployer, nftMainInstance, erc721Instance } = await setupTest();

    await nftMainInstance.mint(1, deployer.address);

    await nftMainInstance.burn(1);

    await expect(erc721Instance.ownerOf(1))
      .to.be.revertedWithCustomError(nftMainInstance, "ERC721NonexistentToken")
      .withArgs(1);
  });
});
