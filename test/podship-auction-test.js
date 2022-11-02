const { assert } = require("chai");
const { ethers } = require("hardhat");

describe("PodshipAuction", async function(){
    let PodShipContract, deployedPodShip, PodShipNFTContract, deployedPodShipNFT;
    beforeEach(async function(){
        // Auction smart contract deployment
        PodShipContract = await ethers.getContractFactory("PodShipAuction");
        deployedPodShip = await PodShipContract.deploy(5, "0x66d126586d17e27A3E57A2C0301ebc0cCA2c45C7", "0xb74BcaBBbE5BC2De2540F34B0BB2549f62893A8d", "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed", "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", "2368", "2500000");
        await deployedPodShip.deployed();

        // NFT smart contract deployment
        PodShipNFTContract = await ethers.getContractFactory("PodShipSupporterNFT");
        deployedPodShipNFT = await PodShipNFTContract.deploy();
        await deployedPodShipNFT.deployed();
        console.log(`PodShipNFT Contract Address: ${deployedPodShipNFT.address}`);
    })

    it ("it should mint a supporters NFT successfully to owners address", async function(){
        let targetOwnerAddress = "0x10A6926348861E90BFB466C6CEe4205befcd30C3"
        let nftTransaction = await PodShipNFTContract.mint(targetOwnerAddress, 5, targetTokenId, "")
        await nftTransaction.wait(1)
        let currentTargetOwnerAddress = await PodShipNFTContract.getNftOwner(5)
        assert.equal(currentTargetOwnerAddress, targetOwnerAddress)
        
    })

    it ("It should deploy successfully by setting platform fee to 5", async function(){
        let targetPlatformFee = "5";
        let currentPlatformFee = await deployedPodShip.platformFee();
        assert.equal(currentPlatformFee, targetPlatformFee);
    })

    it ("it should start an Auction successfully", async function(){
        let targetReservedPrice = "4"
        let auctionTxn = await PodShipContract.startAuction(5, targetReservedPrice, 7, 5);
        await auctionTxn.wait(1)
        
        let auctions = await  PodShipContract.auctions[0]
        assert.equal(auctions.reservedPrice, targetReservedPrice)
        
    })

    it ("it should place a Bid", async function(){
        let targetReservedPrice = "4"
        let auctionTxn = await PodShipContract.startAuction(5, targetReservedPrice, 7, 5);
        await auctionTxn.wait(1)
        
        let BidauctionTxn = await PodShipContract.bid(0);
        await BidauctionTxn.wait(1)
        
        let auctions = await PodShipContract.auctions[0]
        assert.equal(auctions.reservedPrice, targetReservedPrice)
        await auctionTxn.wait(1)

        
    })

    it ("it should end an Auction successfully", async function(){
        let auctionTxn = await PodShipContract.endAuction(2);
        await auctionTxn.wait(1)
        
    })

    it ("it should cancel an Auction successfully", async function(){
        let auctionTxn = await PodShipContract.cancelAuction(2);
        await auctionTxn.wait(1)
        
    })

    it ("it should refund a bid successfully", async function(){
        let auctionTxn = await PodShipContract.refundBid(2);
        await auctionTxn.wait(1)
        
    })


    it ("it should perform a check upkeep and know if upkeep is needed", async function(){
        let auctionTxn = await PodShipContract.checkUpkeep();
        await auctionTxn.wait(1)
        
    })

    it ("it should execute a perform upkeep function and know if upkeep is needed", async function(){
        let auctionTxn = await PodShipContract.performUpkeep();
        await auctionTxn.wait(1)
        
    })

    it ("it should fulfil random words", async function(){
        let auctionTxn = await PodShipContract.fulfillRandomWords(1, "jay");
        await auctionTxn.wait(1)
        
    })

    it ("it should change platform fee recipient", async function(){
        let auctionTxn = await PodShipContract.changePlatformFee(5);
        await auctionTxn.wait(1)
        
    })

    it ("it should change platform fee", async function(){
        let auctionTxn = await PodShipContract.changePlatformFeeRecipient("0x10A6926348861E90BFB466C6CEe4205befcd30C3");
        await auctionTxn.wait(1)
        
    })

    it ("it should Withdraw amount placed on Bid", async function(){
        let auctionTxn = await PodShipContract.withdraw(5, 4, 7, 5);
        await auctionTxn.wait(1)
        
    })
})
