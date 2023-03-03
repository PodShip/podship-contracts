// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PodShipErrors.sol";
import "hardhat/console.sol";
import {PodShip} from "./PodShip.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

///// @notice PodShip's Auctions core contract
contract PodShipAuction is Ownable, PodShip, ERC2981, ReentrancyGuard {
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
    event PlatformFeeChanged(
        uint256 indexed platformFee
    );
    event PlatformFeeRecipientChanged(
        address indexed platformFeeRecipient
    );
    event BidRefunded(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bid
    );
    event RequestedWinner(uint256 indexed requestId);
    event RecentWinner(address indexed recentWinner);
    
    uint256 private platformFee;
    uint256 public constant MAX_PLATFORM_FEE = 10;
    address private platformFeeRecipient;

    constructor(uint256 _platformFee, address _platformFeeRecipient){
        require(_platformFee <= MAX_PLATFORM_FEE);
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

    /// @dev mapinng msgSender -> msgValue -> auctionId
    mapping(address => mapping(uint => uint)) public bids;

    /// @dev Only NFT Owner can start the auction, Auction Duration days can be 1 to 7 days long, Royalty Percent can on be between 1 & 50 and reserve prive should be more than 1 MATIC.
    /// @param _reservePrice - Auction starting price for the NFT
    /// @param _duration - Duration of the Auction in days
    /// @param _royaltyPercent - Royalty Percentage NFT creator will get on the resales
    function startAuction(uint256 _podcastId, uint256 _reservePrice, uint256 _duration, uint96 _royaltyPercent) public returns(uint256) {
        if(msg.sender != ownerOf(_podcastId)){ revert PodShipAuction__OnlyNftOwnerCanStartTheAuction(); }
        if(_duration < 1){ revert PodShipAuction__AuctionDuration_1to7_DaysAllowed(); }
        if(_duration > 7){ revert PodShipAuction__AuctionDuration_1to7_DaysAllowed(); }
        if(_royaltyPercent < 1){ revert PodShipAuction__NftRoyalties_1to50_PercentAllowed(); }
        if(_royaltyPercent > 50){ revert PodShipAuction__NftRoyalties_1to50_PercentAllowed(); }
        if(_reservePrice < 1){ revert PodShipAuction__ReservePriceZeroNotAllowed(); }
        auctionId.increment();
        approve(address(this), podcastId[_podcastId].tokenId);
        // uint256 auction_duration = _duration * 86400;   ///// For Mainnet
        uint256 auction_duration = _duration * 60;         ///// For testnet/testing
        _setTokenRoyalty(podcastId[_podcastId].tokenId, podcastId[_podcastId].nftCreator, _royaltyPercent);
        auctions[auctionId.current()] = Auction(_podcastId, _reservePrice * 10**18, 0, 0, auction_duration, _royaltyPercent, true);

        emit AuctionCreated(auctionId.current(), _reservePrice * 10**18, _royaltyPercent, _podcastId, auction_duration);
        return auctionId.current();
    }

    function bid(uint256 _auctionId) public payable {
        if(msg.sender == podcastId[auctions[_auctionId].podcastId].nftOwner){ revert PodShipAuction__NftOwnerCannotBid(); }
        if(!auctions[_auctionId].listed){ revert PodShipAuction__NftNotOnAuction(); }
        if(bidders[_auctionId].highestBidder == address(0)) {
            auctions[_auctionId].startTime = block.timestamp;
        }
        auctions[_auctionId].endTime = auctions[_auctionId].startTime + auctions[_auctionId].duration;
        if(block.timestamp > auctions[_auctionId].endTime){ revert PodShipAuction__AuctionEnded(); }
        if(msg.value == 0) { revert PodShipAuction__InputAmountCannotBeZero(); }
        if(msg.value < auctions[_auctionId].reservePrice){
            revert PodShipAuction__InputAmountBelowNftReservePrice();
        }
        if(msg.value <= bidders[_auctionId].highestBid){
            revert PodShipAuction__InputAmountBelowNftLastHighestBid();
        }
        if (msg.sender != address(0)) {
            bids[msg.sender][_auctionId] += msg.value;
        }
        bidders[_auctionId].highestBidder = msg.sender;
        bidders[_auctionId].highestBid = msg.value;

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public nonReentrant {
        if(!auctions[_auctionId].listed){ revert PodShipAuction__NftNotOnAuction(); }
        if(msg.sender != podcastId[auctions[_auctionId].podcastId].nftOwner){ revert PodShipAuction__OnlyNftOwnerAllowed(); }
        if(block.timestamp < auctions[_auctionId].endTime) { revert PodShipAuction__AuctionInProgress(); }
        auctions[_auctionId].listed = false;
        safeTransferFrom(podcastId[auctions[_auctionId].podcastId].nftOwner, bidders[_auctionId].highestBidder, podcastId[auctions[_auctionId].podcastId].tokenId);
        uint256 platformCut = (platformFee * bidders[_auctionId].highestBid)/100;
        uint256 NftOwnerCut = bidders[_auctionId].highestBid - platformCut;
        (bool pass, ) = payable(platformFeeRecipient).call{value: platformCut}("");
        if(!pass){ revert PodShipAuction__platformFeeTransferFailed(); }
        (bool success, ) = payable(podcastId[auctions[_auctionId].podcastId].nftOwner).call{value: NftOwnerCut}("");
        if(!success){ revert PodShipAuction__NftOwnerCutTransferFailed(); }
        podcastId[auctions[_auctionId].podcastId].nftOwner = bidders[_auctionId].highestBidder;

        emit AuctionResulted(_auctionId, bidders[_auctionId].highestBidder, bidders[_auctionId].highestBid);
        bidders[_auctionId].highestBid = 0;
        auctions[_auctionId].endTime = 0;
    }

    function cancelAuction(uint256 _auctionId) public {
        if(msg.sender != podcastId[auctions[_auctionId].podcastId].nftOwner){ revert PodShipAuction__OnlyAuctionCreatorAllowed(); }
        if(msg.sender != podcastId[auctions[_auctionId].podcastId].nftCreator){ revert PodShipAuction__OnlyAuctionCreatorAllowed(); }
        delete auctions[_auctionId];
        
        emit AuctionCancelled(_auctionId);
    }

    function refundBid(uint256 _auctionId) public nonReentrant {
        if(msg.sender == bidders[_auctionId].highestBidder){ revert PodShipAuction__AuctonWinnerCannotWithdraw();}
        if(bids[msg.sender][_auctionId] == 0){ revert PodShipAuction__UserDidNotParticipatedInTheAuction(); }
        uint256 refundAmount = bids[msg.sender][_auctionId];
        bids[msg.sender][_auctionId] = 0;
        (bool sent, ) = payable(msg.sender).call{value: refundAmount}("");
        if(!sent){ revert PodShipAuction__WithdrawFailed(); }
        emit BidRefunded(_auctionId, msg.sender, refundAmount);
    }

    function withdraw() external onlyOwner {
        (bool withdrawn, ) = payable(owner()).call{value: address(this).balance}("");
        if(!withdrawn){revert PodShipAuction__WithdrawFailed(); }
    }

    function changePlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= MAX_PLATFORM_FEE);
        platformFee = _platformFee;
        emit PlatformFeeChanged(_platformFee);
    }

    function changePlatformFeeRecipient(address _platformFeeRecipient) external onlyOwner {
        platformFeeRecipient = _platformFeeRecipient;
        emit PlatformFeeRecipientChanged(_platformFeeRecipient);
    }

    function getPlatformFee() public view returns(uint256) {
        return platformFee;
    }
    function getPlatformFeeRecipient() public view returns(address) {
        return platformFeeRecipient;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}