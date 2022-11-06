const { assert } = require("chai");
const { ethers } = require("hardhat");

describe("PodshipAuction", async function () {
    let PodShipAuctionFactory, PodShipAuction, PodShipNFTContractFactory, PodShipNFT, PodShipSupporterNFTContractFactory, PodSupporterShipNFT;
    // const owner = ethers.provider;

    let ipfs = "chain.link/docs"
    beforeEach(async function () {
        //Supporter NFT smart contract deployment
        PodShipSupporterNFTContractFactory = await ethers.getContractFactory("PodShipSupporterNFT");
        PodSupporterShipNFT = await PodShipSupporterNFTContractFactory.deploy();
        await PodSupporterShipNFT.deployed();
        // console.log(`Podship Supporter NFT Contract Address: ${PodSupporterShipNFT.address}`);
        // NFT smart contract deployment
        PodShipNFTContractFactory = await ethers.getContractFactory("PodShip");
        PodShipNFT = await PodShipNFTContractFactory.deploy(PodSupporterShipNFT.address);
        await PodShipNFT.deployed();
        // console.log(`PodShipNFT Contract Address: ${PodShipNFT.address}`);

        // Auction smart contract deployment
        PodShipAuctionFactory = await ethers.getContractFactory("PodShipAuction");
        PodShipAuction = await PodShipAuctionFactory.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7", PodShipNFT.address, "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", "2368", "2500000");
        await PodShipAuction.deployed();
        // console.log(`Podship Auction Contract Address: ${PodShipAuction.address}`);
    })

    it("it should mint a supporters NFT successfully to owners address", async function () {
        const [owner, addr1] = await ethers.getSigners();

        let nftTransaction = await PodShipNFT.mintNFT(ipfs)
        await nftTransaction.wait(1)
        let currentTargetOwnerAddress = await PodShipNFT.getNftOwner(1)

        assert.equal(currentTargetOwnerAddress, owner.address)
    })

    it("It should deploy successfully by setting platform fee to 5", async function () {
        let targetPlatformFee = "5";
        let currentPlatformFee = await PodShipAuction.platformFee();
        assert.equal(currentPlatformFee, targetPlatformFee);
    })

    it("it should start an Auction successfully!", async function () {
        const [owner, addr1] = await ethers.getSigners();

        let nftTransaction = await PodShipNFT.mintNFT(ipfs)
        console.log(await PodShipNFT.getNftOwner(1), "WHEEl", owner.address)
        // await nftTransaction.wait(1)
        let targetReservedPrice = "4"
        
        let auctionTxn = await PodShipAuction.startAuction("1", targetReservedPrice, "7", "5");
        await auctionTxn.wait(1)
        console.log(targetReservedPrice, "HUL")

        let auctions = await PodShipAuction.auctions()
        console.log(auctions.reservedPrice, targetReservedPrice, "CHECK")

        assert.equal(auctions[1].reservedPrice, targetReservedPrice)

    })

    it("it should place a Bid", async function () {
        let targetReservedPrice = "1"
        let targetBid = "2"
        let targetOwnerAddress = "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"
        let nftTransaction = await PodShipNFT.mintPodShipSupporterNFT(targetOwnerAddress)
        await nftTransaction.wait(1)
        let auctionTxn = await PodShipAuction.startAuction(1, targetReservedPrice, 7, 5);
        await auctionTxn.wait(1)

        let BidauctionTxn = await PodShipAuction.bid(1);
        await BidauctionTxn.wait(1)

        let auctions = await PodShipAuction.auctions[0]
        assert.equal(auctions.reservedPrice, targetReservedPrice)


    })

    it("it should end an Auction successfully", async function () {
        let auctionTxn = await PodShipAuction.endAuction(0);
        await auctionTxn.wait(1)
        let auctions = await PodShipAuction.auctions[0]
        assert.isFalse(auctions.listed)

    })

    it("it should cancel an Auction successfully", async function () {
        let auctionTxn = await PodShipAuction.cancelAuction(0);
        await auctionTxn.wait(1)
        let auctions = await PodShipAuction.auctions[0]
        assert.isFalse(auctions.listed)

    })

    it("it should refund a bid successfully", async function () {
        let auctionTxn = await PodShipAuction.refundBid(0);
        await auctionTxn.wait(1)

    })


    it("it should perform a check upkeep and know if upkeep is needed", async function () {
        let auctionTxn = await PodShipAuction.checkUpkeep();
        await auctionTxn.wait(1)

    })

    it("it should execute a perform upkeep function and know if upkeep is needed", async function () {
        let auctionTxn = await PodShipAuction.performUpkeep();
        await auctionTxn.wait(1)

    })

    it("it should fulfil random words", async function () {
        let auctionTxn = await PodShipAuction.fulfillRandomWords(1, "jay");
        await auctionTxn.wait(1)

    })

    it("it should change platform fee recipient", async function () {
        let targetPlatformFee = "5"
        let auctionTxn = await PodShipAuction.changePlatformFee(targetPlatformFee);
        await auctionTxn.wait(1)
        let currentPlatformFee = await PodShipAuction.platformFee()
        assert.equal(currentPlatformFee == targetPlatformFee)

    })

    it("it should change platform fee", async function () {
        let targetPlatformFeeRecipient = "0xbDA5747bFD65F08deb54cb465eB87D40e51B197E"
        let auctionTxn = await PodShipAuction.changePlatformFeeRecipient(targetPlatformFeeRecipient);
        await auctionTxn.wait(1)

        let currentPlatformFeeRecipient = await PodShipAuction.platformFeeRecipient()
        assert.equal(currentPlatformFeeRecipient == targetPlatformFeeRecipient)

    })

    it("it should Withdraw amount placed on Bid", async function () {
        let auctionTxn = await PodShipAuction.withdraw();
        await auctionTxn.wait(1)

    })
})
