const {ethers} = require("hardhat");
require("dotenv").config({ path: ".env" });

PRIVATE_KEY = process.env.PRIVATE_KEY;
const wallet = new ethers.Wallet(PRIVATE_KEY, ethers.provider)

async function main() {
    console.log("Wallet Ethereum Address:", wallet.address)
    const PodShipContract = await ethers.getContractFactory("PodShipAuction", wallet);
    const deployedPodShip = await PodShipContract.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7");
    await deployedPodShip.deployed();
    console.log(`PodShip Contract Address: ${deployedPodShip.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});