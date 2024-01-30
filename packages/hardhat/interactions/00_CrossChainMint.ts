import { JsonRpcProvider, Wallet, Contract } from "ethers";
import { ethers } from "hardhat";
import IERC20 from "../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json";

async function testCrossChainMint() {
  console.log("Starting");
  const contractAddress = "0x88d73C4d056c3AAaAc25102CA65abc8C097340cf";
  const avaxFujiLinkAddress = "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846";

  const mumbaiSelector = 12532609583862916517n;
  const avaxFujiSelector = 14767482510784806043n;

  const avaxFujiProvider = new JsonRpcProvider("https://rpc.ankr.com/avalanche_fuji");

  const avaxSigner = new Wallet(process.env.DPK!, avaxFujiProvider);

  const avaxLinkInstance = await ethers.getContractAt(IERC20.abi, avaxFujiLinkAddress, avaxSigner);

  //  -- ONLY DO THIS ONCE -- //
  console.log("Step 1: Transfering 5 LINK to the contract");
  const fundContractWithLink = await avaxLinkInstance.transfer(contractAddress, ethers.parseEther("5.0"));
  await fundContractWithLink.waitConfirmations(5);

  const avaxCCIPContract = await ethers.getContractAt("CCIPFacet", contractAddress, avaxSigner);
  const avaxCCMintContract = await ethers.getContractAt("NftCrossChainMinter", contractAddress, avaxSigner);

  console.log("Step 2: Allowing Destination Chain");
  await avaxCCIPContract.allowlistDestinationChain(mumbaiSelector, true);

  console.log("--- Switching to Mumbai ---");
  const mumbaiProvider = new JsonRpcProvider(
    "https://polygon-mumbai.g.alchemy.com/v2/oKxs-03sij-U_N0iOlrSsZFr29-IqbuF",
  );
  const mumbaiSigner = new Wallet(process.env.DPK!, mumbaiProvider);

  const mumbaiContract = await ethers.getContractAt("CCIPFacet", contractAddress, mumbaiSigner);
  const mumbaiNftInstance = await ethers.getContractAt("ERC721Facet", contractAddress, mumbaiSigner);

  console.log("Step 3: Allowing Source Chain");
  await mumbaiContract.allowlistSourceChain(avaxFujiSelector, true);

  console.log("Step 4: Allowing Sender");
  await mumbaiContract.allowlistSender(contractAddress, true);

  console.log("Step 5: Minting NFT from AVAX to Polygon");
  await avaxCCMintContract.mintCrossChainPayLINK(mumbaiSelector, contractAddress, 1);

  console.log("Complete");
}

testCrossChainMint();
