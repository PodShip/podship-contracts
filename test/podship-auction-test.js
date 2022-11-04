const { assert } = require("chai");
const { ethers } = require("hardhat");

describe("PodshipAuction", async function () {
    let PodShipContractFactory, deployedPodShip, PodShipNFTContractFactory, deployedPodShipNFT;
    beforeEach(async function () {
        // Auction smart contract deployment
        PodShipContractFactory = await ethers.getContractFactory("PodShipAuction");
        deployedPodShip = await PodShipContractFactory.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7", "0xb74BcaBBbE5BC2De2540F34B0BB2549f62893A8d", "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", "2368", "2500000");
        await deployedPodShip.deployed();

        // NFT smart contract deployment
        PodShipNFTContractFactory = await ethers.getContractFactory("PodShip");
        deployedPodShipNFT = await PodShipNFTContractFactory.deploy("0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7");
        await deployedPodShipNFT.deployed();
        console.log(`PodShipNFT Contract Address: ${deployedPodShipNFT.address}`);

      
    })

    it("it should mint a supporters NFT successfully to owners address", async function () {
        let targetOwnerAddress = "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"
        let nftTransaction = await deployedPodShipNFT.mintNFT(targetOwnerAddress)
        await nftTransaction.wait(1)
        let currentTargetOwnerAddress = await deployedPodShipNFT.getNftOwner(1)
        assert.equal(currentTargetOwnerAddress, targetOwnerAddress)

    })

    it("It should deploy successfully by setting platform fee to 5", async function () {
        let targetPlatformFee = "5";
        let currentPlatformFee = await deployedPodShip.platformFee();
        assert.equal(currentPlatformFee, targetPlatformFee);
    })

    it("it should start an Auction successfully", async function () {
        let targetReservedPrice = "4"
        let auctionTxn = await deployedPodShip.startAuction(1, targetReservedPrice, 7, 5);
        await auctionTxn.wait(1)

        let auctions = await deployedPodShip.auctions[1]
        assert.equal(auctions.reservedPrice, targetReservedPrice)

    })

    it("it should place a Bid", async function () {
        let targetReservedPrice = "1"
        let targetBid = "2"
        let targetOwnerAddress = "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"
        let nftTransaction = await deployedPodShipNFT.mintPodShipSupporterNFT(targetOwnerAddress)
        await nftTransaction.wait(1)
        let auctionTxn = await deployedPodShip.startAuction(1, targetReservedPrice, 7, 5);
        await auctionTxn.wait(1)

        let BidauctionTxn = await deployedPodShip.bid(1);
        await BidauctionTxn.wait(1)
        
        let auctions = await deployedPodShip.auctions[0]
        assert.equal(auctions.reservedPrice, targetReservedPrice)
    

    })

    it("it should end an Auction successfully", async function () {
        let auctionTxn = await deployedPodShip.endAuction(0);
        await auctionTxn.wait(1)
        let auctions = await deployedPodShip.auctions[0]
        assert.isFalse(auctions.listed)

    })

    it("it should cancel an Auction successfully", async function () {
        let auctionTxn = await deployedPodShip.cancelAuction(0);
        await auctionTxn.wait(1)
        let auctions = await deployedPodShip.auctions[0]
        assert.isFalse(auctions.listed)

    })

    it("it should refund a bid successfully", async function () {
        let auctionTxn = await deployedPodShip.refundBid(0);
        await auctionTxn.wait(1)

    })


    it("it should perform a check upkeep and know if upkeep is needed", async function () {
        let auctionTxn = await deployedPodShip.checkUpkeep();
        await auctionTxn.wait(1)

    })

    it("it should execute a perform upkeep function and know if upkeep is needed", async function () {
        let auctionTxn = await deployedPodShip.performUpkeep();
        await auctionTxn.wait(1)

    })

    it("it should fulfil random words", async function () {
        let auctionTxn = await deployedPodShip.fulfillRandomWords(1, "jay");
        await auctionTxn.wait(1)

    })

    it("it should change platform fee recipient", async function () {
        let targetPlatformFee = "5"
        let auctionTxn = await deployedPodShip.changePlatformFee(targetPlatformFee);
        await auctionTxn.wait(1)
        let currentPlatformFee = await deployedPodShip.platformFee()
        assert.equal(currentPlatformFee == targetPlatformFee)

    })

    it("it should change platform fee", async function () {
        let targetPlatformFeeRecipient = "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"
        let auctionTxn = await deployedPodShip.changePlatformFeeRecipient(targetPlatformFeeRecipient);
        await auctionTxn.wait(1)

        let currentPlatformFeeRecipient = await deployedPodShip.platformFeeRecipient()
        assert.equal(currentPlatformFeeRecipient == targetPlatformFeeRecipient)

    })

    it("it should Withdraw amount placed on Bid", async function () {
        let auctionTxn = await deployedPodShip.withdraw();
        await auctionTxn.wait(1)

    })
})
