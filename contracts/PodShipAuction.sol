// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./PodShip.sol";

contract PodShipAuction is PodShip {
    using Counters for Counters.Counter;
    Counters.Counter private auctionId;

    uint256 public immutable platformFee;
    address public immutable platformFeeRecipient;

    constructor(uint256 _platformFee, address _platformFeeRecipient) {
        platformFee = _platformFee;
        platformFeeRecipient = _platformFeeRecipient;
    }

    struct Auction {
        uint256 podcastId;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool listed;
        // uint256 royalty;
    }

    struct Bidding {
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bidding) public bidders;
    mapping(address => uint) public bids;
    

    function startAuction(uint256 _podcastId, uint256 _reservePrice, uint256 _startTime, uint256 _endTime) public returns(uint256) {
        require(msg.sender == ownerOf(_podcastId), "only NFT Owner can start the Auction");
        require(!podcastId[_podcastId].listed, "NFT already on Auction");
        auctionId.increment();
        podcastId[_podcastId].listed = true;
        approve(address(this), 1);
        auctions[auctionId.current()] = Auction(_podcastId, _reservePrice, _startTime, _endTime, true);
        return auctionId.current();
    }

    function bid(uint256 _auctionId) public payable {
        require(!isContract(msg.sender), "only EOA allowed");
        require(auctions[_auctionId].listed, "NFT not on Auction");
        require(block.timestamp > auctions[_auctionId].startTime, "Auction not started yet");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction Ended");
        require(msg.value > auctions[_auctionId].reservePrice && msg.value > bidders[_auctionId].highestBid, "Input amount below NFT's reservePrice or last Bid");
        if (msg.sender != address(0)) {
            bids[msg.sender] += msg.value;
        }
        bidders[_auctionId].highestBidder = msg.sender;
        bidders[_auctionId].highestBid = msg.value;
    }

    function endAuction(uint256 _auctionId, uint256 _podcastId) public payable {
        require(auctions[_auctionId].listed, "NFT not on Auction");
        require(block.timestamp > auctions[_auctionId].endTime, "Auction In Progress");
        require(msg.sender == podcastId[_podcastId].nftOwner || msg.sender == bidders[_auctionId].highestBidder, "Only Auction Creator & Winner allowed");
        podcastId[_podcastId].listed = false;
        safeTransferFrom(podcastId[_podcastId].nftOwner, bidders[_auctionId].highestBidder, podcastId[_podcastId].tokenId);
        (bool success, ) = (podcastId[_podcastId].nftOwner).call{value: bidders[_auctionId].highestBid}("");
        require(success, "NFT Tranfership Failed");
    }

    function deleteAuction(uint256 _auctionId) public {
        delete auctions[_auctionId];
    }

    function withdrawBids(uint256 _podcastId) public payable {
        require(!podcastId[_podcastId].listed, "Auction still in Progress");
        require(bids[msg.sender] != 0, "User didt participated in the Auction");
        (bool sent, ) = payable(msg.sender).call{value: bids[msg.sender]}("");
        require(sent, "Withdraw Failed");
    }

    // function testNavich() public view returns(uint256) {
    //     return bids[msg.sender];
    // }

    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}