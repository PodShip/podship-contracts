const {ethers} = require("hardhat");

const util = require("util")
const request = util.promisify(require("request"))

PRIVATE_KEY = process.env.PRIVATE_KEY;
const deployer = new ethers.Wallet(PRIVATE_KEY)

async function callRpc(method, params) {
    var options = {
        method: "POST",
        url: "https://api.zondax.ch/fil/node/hyperspace/rpc/v0",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            jsonrpc: "2.0",
            method: method,
            params: params,
            id: 1,
        }),
    }
    const res = await request(options)
    return JSON.parse(res.body).result
}

async function main() {

  const priorityFee = await callRpc("eth_maxPriorityFeePerGas")   
  const PodShipContract = await ethers.getContractFactory("PodShipAuction");
  const deployedPodShip = await PodShipContract.deploy({
    from: deployer.address,
    args: [],
    maxPriorityFeePerGas: priorityFee,
    log: true,
});
  await deployedPodShip.deployed();
  console.log(`PodShip Contract Address: ${deployedPodShip.address}`);

  console.log("Waiting for block confirmations & Verifying.....")
  await deployedPodShip.deployTransaction.wait(5)
  await verify(deployedPodShip.address, [])
}

const verify = async (contractAddress, args) => {
  console.log("Verifying contract.....")
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