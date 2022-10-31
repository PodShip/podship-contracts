const {ethers} = require("hardhat");

async function main() {
  const PodShipNFTContract = await ethers.getContractFactory("PodShipSupporterNFT");
  const deployedPodShipNFT = await PodShipNFTContract.deploy();
  await deployedPodShipNFT.deployed();
  console.log(`PodShipNFT Contract Address: ${deployedPodShipNFT.address}`);

    console.log("Waiting for block confirmations & Verifying...")
    await deployedPodShipNFT.deployTransaction.wait(5)
    await verify(deployedPodShipNFT.address, [])
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