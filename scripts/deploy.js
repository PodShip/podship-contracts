const {ethers} = require("hardhat");

async function main() {
  const PodShipContract = await ethers.getContractFactory("PodShipAuction");
  const deployedPodShip = await PodShipContract.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7");
  await deployedPodShip.deployed();
  console.log(`PodShip Contract Address: ${deployedPodShip.address}`);

  // if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
    console.log("Waiting for block confirmations & Verifying...")
    await deployedPodShip.deployTransaction.wait(5)
    await verify(deployedPodShip.address, [5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7"])
  // } else {
  //   console.log("Verification Falied");
  // }
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