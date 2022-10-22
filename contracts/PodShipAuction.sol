// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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
        uint256 duration;
        bool listed;
    }

    struct Bidding {
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bidding) public bidders;
    mapping(address => uint) public bids;
    

    function startAuction(uint256 _podcastId, uint256 _reservePrice, uint256 _duration) public returns(uint256) {
        require(msg.sender == ownerOf(_podcastId), "only NFT Owner can start the Auction");
        require(_duration >= 1 && _duration <= 7, "Auction duration can be between 1-7 Days");
        auctionId.increment();
        approve(address(this), podcastId[_podcastId].tokenId);
        // uint256 auction_duration = _duration * 86400; ///// For Mainnet
        uint256 auction_duration = _duration * 60; ///// For testnet-testing
        auctions[auctionId.current()] = Auction(_podcastId, _reservePrice, 0, auction_duration, true);
        return auctionId.current();
    }

    function bid(uint256 _auctionId) public payable {
        require(auctions[_auctionId].listed, "NFT not on Auction");
        if(bidders[_auctionId].highestBidder == address(0)) {
            auctions[_auctionId].startTime = block.timestamp;
        }
        auctions[_auctionId].duration = auctions[_auctionId].startTime + auctions[_auctionId].duration;
        require(block.timestamp < auctions[_auctionId].duration, "Auction Ended");
        require(msg.value > auctions[_auctionId].reservePrice && msg.value > bidders[_auctionId].highestBid, "Input amount below NFT's reservePrice or last Bid");
        if (msg.sender != address(0)) {
            bids[msg.sender] += msg.value;
        }
        bidders[_auctionId].highestBidder = msg.sender;
        bidders[_auctionId].highestBid = msg.value;
    }

    // Reentrancy Gaurd needed here:
    function endAuction(uint256 _auctionId) public payable {
        require(auctions[_auctionId].listed, "NFT not on Auction");
        require(block.timestamp > auctions[_auctionId].startTime + auctions[_auctionId].duration, "Auction In Progress");
        require(msg.sender == podcastId[auctions[_auctionId].podcastId].nftOwner || msg.sender == bidders[_auctionId].highestBidder, "Only Auction Creator & Winner allowed");
        auctions[_auctionId].listed = false;
        safeTransferFrom(podcastId[auctions[_auctionId].podcastId].nftOwner, bidders[_auctionId].highestBidder, podcastId[auctions[_auctionId].podcastId].tokenId);
        (bool success, ) = (podcastId[auctions[_auctionId].podcastId].nftOwner).call{value: bidders[_auctionId].highestBid}("");
        podcastId[auctions[_auctionId].podcastId].nftOwner = bidders[_auctionId].highestBidder;
        require(success, "NFT Tranfership Failed");
    }

    function deleteAuction(uint256 _auctionId) public {
        require(msg.sender == podcastId[auctions[_auctionId].podcastId].nftOwner && msg.sender == podcastId[auctions[_auctionId].podcastId].nftCreator, "Only Auction Creator allowed");
        delete auctions[_auctionId];
    }

    function withdrawBidsMoney(uint256 _auctionId) public payable {
        require(msg.sender != bidders[_auctionId].highestBidder, "Aucton Winner cannot withdraw");
        require(!auctions[_auctionId].listed, "Auction still in Progress");
        require(bids[msg.sender] != 0, "User didt participated in the Auction");
        (bool sent, ) = payable(msg.sender).call{value: bids[msg.sender]}("");
        require(sent, "Withdraw Failed");
    }

}