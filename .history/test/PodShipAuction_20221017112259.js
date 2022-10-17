const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

const Auction = artifacts.require('PodShipAuction');
const MockNft = artifacts.require('PodNFT');

contract('pod ship auction', async ([alice, bob, dev, admin, minter]) => {

  function now() {
    return Math.round(Date.now() / 1000)
  }

  beforeEach(async () => {
    
    //////////////////////////
    //  Deploy contracts    //
    //////////////////////////

    this.mockNft = await MockNft.new({
      from: minter
    })

    this.auctionContract = await Auction.new(this.accessControlContract.address, this.mockNft.address, admin, {
      from: minter
    })
    
    // create some amount of nfts
    await this.mockNft.mint(alice, {
      from: alice
    })

  })

  it('general flow', async () => {

    await this.mockNft.setApprovalForAll(this.auctionContract.address, true)
    
    const tokenIdOfAlice = 1

    let owner = await this.mockNft.ownerOf(tokenIdOfAlice);
    assert.equal(owner, alice)

    await this.auctionContract.createAuction(tokenIdOfAlice, web3.utils.toWei('0.1'), now(), now() + 24 * 3600, {
      from: alice
    })

    

   

    await time.increase(time.duration.days(2));

    

    owner = await this.mockNft.ownerOf(tokenIdOfAlice);

    assert.equal(owner, bob)
    
  })

  it("withdraw bid", async () => {

    await this.mockNft.setApprovalForAll(this.auctionContract.address, true)
    
    const tokenIdOfAlice = 1

    let owner = await this.mockNft.ownerOf(tokenIdOfAlice);
    assert.equal(owner, alice)

   
  })

  it("cancel auction", async () => {

    await this.mockNft.setApprovalForAll(this.auctionContract.address, true)
    
    const tokenIdOfAlice = 1

    let owner = await this.mockNft.ownerOf(tokenIdOfAlice);
    assert.equal(owner, alice)

    await time.increase(time.duration.days(2));

    await this.auctionContract.cancelAuction(tokenIdOfAlice, {
      from: alice
    })

    const balance = await web3.eth.getBalance(bob)
    // assert.isAbove(balance, web3.utils.toWei(99.9), "funds not returned back")

  })

  it("test read functions", async () => {
    await this.mockNft.setApprovalForAll(this.auctionContract.address, true)
    
    const tokenIdOfAlice = 1

   

    await this.auctionContract.placeBid(tokenIdOfAlice, {
      from: dev,
      value: web3.utils.toWei('0.1')
    })

    await this.auctionContract.placeBid(tokenIdOfAlice, {
      from: bob,
      value: web3.utils.toWei('0.5')
    })

    const auction = await this.auctionContract.getAuction(tokenIdOfAlice)
    console.log('--- auction info ---')
    assert.equal(auction._reservePrice.toString(), web3.utils.toWei('0.3'))
    assert.equal(auction._resulted, false)
    console.log('reserve price:', auction._reservePrice.toString())
    console.log('start time:', auction._startTime.toString())
    console.log('end time:', auction._endTime.toString())
    console.log('resulted status:', auction._resulted)

    const highestBidder = await this.auctionContract.getHighestBidder(tokenIdOfAlice)
    assert.equal(highestBidder._bidder, bob, "incorrect highest bidder")
    assert.equal(highestBidder._bid.toString(), web3.utils.toWei('0.5'), 'incorrect highest bid amount')

  })

})