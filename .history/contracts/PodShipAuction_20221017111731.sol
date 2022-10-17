// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;


import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice Primary sale auction contract for Cyber Spawn NFTs
 */
contract CyberSpawnNFTAuction {
    using Address for address payable;

    /// @notice Event emitted only on construction. To be used by indexers
    event PodShipAuctionContractDeployed();

    event PauseToggled(
        bool isPaused
    );

    event AuctionCreated(
        uint256 indexed tokenId
    );

    event UpdateAuctionEndTime(
        uint256 indexed tokenId,
        uint256 endTime
    );

    event UpdateAuctionStartTime(
        uint256 indexed tokenId,
        uint256 startTime
    );

    event UpdateAuctionReservePrice(
        uint256 indexed tokenId,
        uint256 reservePrice
    );

    event UpdatePlatformFee(
        uint256 platformFee
    );

    event UpdatePlatformFeeRecipient(
        address payable platformFeeRecipient
    );

    event UpdateMinBidIncrement(
        uint256 minBidIncrement
    );

    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidWithdrawn(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidRefunded(
        address indexed bidder,
        uint256 bid
    );

    event AuctionResulted(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid
    );

    event AuctionCancelled(
        uint256 indexed tokenId
    );

    /// @notice Parameters of an auction
    struct Auction {
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool resulted;
    }

    /// @notice Information about the sender that placed a bit on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    /// @notice NFT Token ID -> Auction Parameters
    mapping(uint256 => Auction) public auctions;

    /// @notice NFT Token ID -> highest bidder info (if a bid has been received)
    mapping(uint256 => HighestBid) public highestBids;

    /// @notice NFT - the only NFT that can be auctioned in this contract
    IERC721 public CyberSpawnNft;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement = 0.1 ether;

    /// @notice global platform fee, assumed to always be to 1 decimal place i.e. 20 = 2.0%
    uint256 public platformFee = 20;

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    modifier whenNotPaused() {
        require(!isPaused, "Function is currently paused");
        _;
    }

    constructor(
        IERC721 _PodShipNft,
        address payable _platformFeeRecipient
    ) public {
        
        
        require(address(_PodShipNft) != address(0), "PodNFTAuction: Invalid NFT");
        require(_platformFeeRecipient != address(0), "NFTAuction: Invalid Platform Fee Recipient");

        CyberSpawnNft = _PodShipNft;
        platformFeeRecipient = _platformFeeRecipient;

        emit PodShipAuctionContractDeployed();
    }

// next functionality

// Create Auction Method => visibility public

// Get Auction => visibility public

// Update Auction End time and start Time

// Place Bid function

// Auction resolution => Highest Bidder gets pod cast

// canc
}