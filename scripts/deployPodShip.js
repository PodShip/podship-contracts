const { ethers } = require("hardhat");

async function main() {

  const PodShipContract = await ethers.getContractFactory("PodShipAuction");
  const deployedPodShip = await PodShipContract.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7", "0xb74BcaBBbE5BC2De2540F34B0BB2549f62893A8d", "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", "2368", "2500000");
  await deployedPodShip.deployed();
  console.log(`PodShip Contract Address: ${deployedPodShip.address}`);

  // if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
  console.log("Waiting for block confirmations & Verifying...")
  await deployedPodShip.deployTransaction.wait(5)
  await verify(deployedPodShip.address, [5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7", "0xb74BcaBBbE5BC2De2540F34B0BB2549f62893A8d", "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", "2368", "2500000"])
  // } else {
  //   console.log("Verification Falied");
  // }

  //Supporter NFT smart contract deployment
  PodShipSupporterNFTContractFactory = await ethers.getContractFactory("PodShipSupporterNFT");
  PodSupporterShipNFT = await PodShipSupporterNFTContractFactory.deploy(ipfs);
  await PodSupporterShipNFT.deployed();
  console.log(`Podship Supporter NFT Contract Address: ${PodSupporterShipNFT.address}`);

  // NFT smart contract deployment
  PodShipNFTContractFactory = await ethers.getContractFactory("PodShip");
  PodShipNFT = await PodShipNFTContractFactory.deploy(PodSupporterShipNFT.address);
  await PodShipNFT.deployed();
  console.log(`PodShipNFT Contract Address: ${PodShipNFT.address}`);

  // Auction smart contract deployment
  PodShipAuctionFactory = await ethers.getContractFactory("PodShipAuction");
  PodShipAuction = await PodShipAuctionFactory.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7", PodShipNFT.address, "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", "2368", "2500000");
  await PodShipAuction.deployed();
  console.log(`Podship Auction Contract Address: ${PodShipAuction.address}`);
}

const verify = async (contractAddress, args) => {
  console.log("Verifying contract...")
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    })
  } catch (e) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already Verified!")
    } else {
      console.log(e)
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });