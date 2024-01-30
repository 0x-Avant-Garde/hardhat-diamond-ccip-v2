import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Interface, ZeroAddress, FunctionFragment, keccak256, solidityPackedKeccak256 } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

/**
 * Deploys contracts using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const [deployer]: SignerWithAddress[] = await ethers.getSigners();
  const { diamond } = hre.deployments;

  const provider = hre.ethers.provider;

  const balanceBefore = await provider.getBalance(deployer.address);

  console.log("Balance Before Deployment", balanceBefore);

  let routerAddress;
  let linkAddress;
  let chainSelector;

  if (hre.network.name == "baseGoerli") {
    routerAddress = "0x80AF2F44ed0469018922c9F483dc5A909862fdc2";
    linkAddress = "0xD886E2286Fd1073df82462ea1822119600Af80b6";
    chainSelector = "5790810961207155433";
  } else if (hre.network.name == "avaxFuji") {
    routerAddress = "0xF694E193200268f9a4868e4Aa017A0118C9a8177";
    linkAddress = "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846";
    chainSelector = "14767482510784806043";
  } else if (hre.network.name == "polygonMumbai") {
    routerAddress = "0x1035CabC275068e0F4b745A29CEDf38E13aF41b1";
    linkAddress = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";
    chainSelector = "12532609583862916517";
  }

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
        routerAddress ?? ZeroAddress, // router
        linkAddress ?? ZeroAddress, // link
      ],
    },
  });

  const balanceAfter = await provider.getBalance(deployer.address);

  console.log("Balance After Deployment", balanceAfter);

  console.log("Difference: ", Number(balanceBefore - balanceAfter) / 1e18);
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["YourContract"];
