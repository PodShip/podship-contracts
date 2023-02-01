require("hardhat-deploy")
require("hardhat-deploy-ethers")

const ethers = require("ethers")
const fa = require("@glif/filecoin-address")
const util = require("util")
const request = util.promisify(require("request"))

PRIVATE_KEY = process.env.PRIVATE_KEY;

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

const deployer = new ethers.Wallet(PRIVATE_KEY)

module.exports = async ({ deployments }) => {
    const { deploy } = deployments

    const priorityFee = await callRpc("eth_maxPriorityFeePerGas")
    const f4Address = fa.newDelegatedEthAddress(deployer.address).toString()
    const nonce = await callRpc("Filecoin.MpoolGetNonce", [f4Address])

    console.log("Wallet Ethereum Address:", deployer.address)
    console.log("Wallet f4Address: ", f4Address)

    const deployedPodShip = await deploy("contracts/PodShipAuction.sol:PodShipAuction", {
        from: deployer.address,
        args: [],
        maxPriorityFeePerGas: priorityFee,
        log: true,
    })
    await deployedPodShip.deployed();
    console.log(`PodShip Contract Address: ${deployedPodShip.address}`);
}

module.exports.tags = ["PodShipAuction"]