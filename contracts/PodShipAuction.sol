// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./PodShip.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract PodShipAuction is Ownable, PodShip, ERC2981, /*AutomationCompatible,*/ ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private auctionId;
    
    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed reservePrice,
        uint96 indexed royaltyPercent,
        uint256 podcastId,
        uint256 duration
    );
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 indexed bid
    );
    event AuctionResulted(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid
    );
    event AuctionCancelled(
        uint256 indexed auctionId
    );
    event BidRefunded(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bid
    );
    
    uint256 public platformFee;
    address public platformFeeRecipient;

    constructor(uint256 _platformFee, address _platformFeeRecipient) {
        platformFee = _platformFee;
        platformFeeRecipient = _platformFeeRecipient;
    }

    struct Auction {
        uint256 podcastId;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        uint256 duration;
        uint96 royaltyPercent;
        bool listed;
    }

    struct Bidding {
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bidding) public bidders;
    mapping(address => uint) public bids;

    function startAuction(uint256 _podcastId, uint256 _reservePrice, uint256 _duration, uint96 _royaltyPercent) public returns(uint256) {
        require(msg.sender == ownerOf(_podcastId), "only NFT Owner can start the Auction");
        require(_duration >= 1 && _duration <= 7, "Auction duration can be between 1-7 Days");
        require(_royaltyPercent >= 1 && _royaltyPercent <= 50, "NFT Royalties should be 1-50 percent");
        require(_reservePrice >= 1, "Reserve Price cannot be Zero");
        auctionId.increment();
        approve(address(this), podcastId[_podcastId].tokenId);
        // uint256 auction_duration = _duration * 86400; ///// For Mainnet
        uint256 auction_duration = _duration * 60;       ///// For testnet/testing
        _setTokenRoyalty(podcastId[_podcastId].tokenId, podcastId[_podcastId].nftCreator, _royaltyPercent);
        auctions[auctionId.current()] = Auction(_podcastId, _reservePrice * 10**18, 0, 0, auction_duration, _royaltyPercent, true);
        emit AuctionCreated(auctionId.current(), _reservePrice * 10**18, _royaltyPercent, _podcastId, auction_duration);
        return auctionId.current();
    }

    function bid(uint256 _auctionId) public payable {
        require(auctions[_auctionId].listed, "NFT not on Auction");
        if(bidders[_auctionId].highestBidder == address(0)) {
            auctions[_auctionId].startTime = block.timestamp;
        }
        auctions[_auctionId].endTime = auctions[_auctionId].startTime + auctions[_auctionId].duration;
        require(block.timestamp < auctions[_auctionId].endTime, "Auction Ended");
        require(msg.value > auctions[_auctionId].reservePrice && msg.value > bidders[_auctionId].highestBid, "Input amount below NFT's reservePrice or last Bid");
        if (msg.sender != address(0)) {
            bids[msg.sender] += msg.value;
        }
        bidders[_auctionId].highestBidder = msg.sender;
        bidders[_auctionId].highestBid = msg.value;
        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public nonReentrant {
        require(auctions[_auctionId].listed, "NFT not on Auction");
        require(msg.sender == podcastId[auctions[_auctionId].podcastId].nftOwner, "Only NFT Owner allowed");
        require(block.timestamp > auctions[_auctionId].endTime, "Auction In Progress");

        auctions[_auctionId].listed = false;

        safeTransferFrom(podcastId[auctions[_auctionId].podcastId].nftOwner, bidders[_auctionId].highestBidder, podcastId[auctions[_auctionId].podcastId].tokenId);

        uint256 platformCut = (platformFee * bidders[_auctionId].highestBid)/100;
        uint256 NftOwnerCut = bidders[_auctionId].highestBid - platformCut;

        (bool pass, ) = platformFeeRecipient.call{value: platformCut}("");
        require(pass, "platformFee Transfer failed");
        (bool success, ) = (podcastId[auctions[_auctionId].podcastId].nftOwner).call{value: NftOwnerCut}("");
        require(success, "NftOwnerCut Transfer Failed");

        podcastId[auctions[_auctionId].podcastId].nftOwner = bidders[_auctionId].highestBidder;
        emit AuctionResulted(_auctionId, bidders[_auctionId].highestBidder, bidders[_auctionId].highestBid);
        bidders[_auctionId].highestBid = 0;
        auctions[_auctionId].endTime = 0;
    }

    function cancelAuction(uint256 _auctionId) public {
        require(msg.sender == podcastId[auctions[_auctionId].podcastId].nftOwner && msg.sender == podcastId[auctions[_auctionId].podcastId].nftCreator, "Only Auction Creator allowed");
        delete auctions[_auctionId];
        emit AuctionCancelled(_auctionId);
    }

    function refundBid(uint256 _auctionId) public payable {
        require(msg.sender != bidders[_auctionId].highestBidder, "Aucton Winner cannot withdraw");
        require(bids[msg.sender] != 0, "User didn't participated in the Auction");
        (bool sent, ) = payable(msg.sender).call{value: bids[msg.sender]}("");
        require(sent, "Withdraw Failed");
        emit BidRefunded(_auctionId, msg.sender, bids[msg.sender]);
    }

    function changePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    function changePlatformFeeRecipient(address _platformFeeRecipient) external onlyOwner {
        platformFeeRecipient = _platformFeeRecipient;
    }

    function withdraw() external onlyOwner payable {
        (bool withdrawn, ) = payable(owner()).call{value: address(this).balance}("");
        require(withdrawn, "Withdraw Failed");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}