// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./AccessControl/CyberSpawnAccessControls.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice Primary sale auction contract for Cyber Spawn NFTs
 */
contract CyberSpawnNFTAuction {
    using Address for address payable;

    /// @notice Event emitted only on construction. To be used by indexers
    event PodAuctionContractDeployed();

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

    event UpdateAccessControls(
        address indexed accessControls
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

    /// @notice responsible for enforcing admin access
    CyberSpawnAccessControls public accessControls;

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
        CyberSpawnAccessControls _accessControls,
        IERC721 _CyberSpawnNft,
        address payable _platformFeeRecipient
    ) public {
        
        require(address(_accessControls) != address(0), "NFTAuction: Invalid Access Controls");
        require(address(_CyberSpawnNft) != address(0), "NFTAuction: Invalid NFT");
        require(_platformFeeRecipient != address(0), "NFTAuction: Invalid Platform Fee Recipient");

        accessControls = _accessControls;
        CyberSpawnNft = _CyberSpawnNft;
        platformFeeRecipient = _platformFeeRecipient;

        emit NFTAuctionContractDeployed();
    }

    /**
     @notice Creates a new auction for a given NFT
     @dev Only the owner of a NFT can create an auction and must have approved the contract
     @dev In addition to owning the NFT, the sender also has to have the MINTER role.
     @dev End time for the auction must be in the future.
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice NFT cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external whenNotPaused {

        // Check owner of the token is the creator and approved
        require(
            CyberSpawnNft.ownerOf(_tokenId) == _msgSender() && CyberSpawnNft.isApprovedForAll(_msgSender(), address(this)),
            "NFTAuction.createAuction: Not owner and or contract not approved"
        );

        _createAuction(
            _tokenId,
            _reservePrice,
            _startTimestamp,
            _endTimestamp
        );
    }


    /**
     @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     @dev Only callable when the auction is open
     @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     @param _tokenId Token ID of the NFT being auctioned
     */
    function placeBid(uint256 _tokenId) external payable nonReentrant whenNotPaused {
        require(_msgSender().isContract() == false, "NFTAuction.placeBid: No contracts permitted");

        // Check the auction to see if this is a valid bid
        Auction storage auction = auctions[_tokenId];

        // Ensure auction is in flight
        require(
            _getNow() >= auction.startTime && _getNow() <= auction.endTime,
            "NFTAuction.placeBid: Bidding outside of the auction window"
        );

        uint256 bidAmount = msg.value;

        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_tokenId];
        uint256 minBidRequired = highestBid.bid.add(minBidIncrement);
        require(bidAmount >= minBidRequired, "NFTAuction.placeBid: Failed to outbid highest bidder");

        // Refund existing top bidder if found
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(highestBid.bidder, highestBid.bid);
        }
        
        // assign top bidder and bid time
        highestBid.bidder = _msgSender();
        highestBid.bid = bidAmount;
        highestBid.lastBidTime = _getNow();

        emit BidPlaced(_tokenId, _msgSender(), bidAmount);
    }

    /**
     @notice Given a sender who has the highest bid on a NFT, allows them to withdraw their bid
     @dev Only callable by the existing top bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function withdrawBid(uint256 _tokenId) external nonReentrant whenNotPaused {
        HighestBid storage highestBid = highestBids[_tokenId];

        // Ensure highest bidder is the caller
        require(highestBid.bidder == _msgSender(), "NFTAuction.withdrawBid: You are not the highest bidder");

        require(_getNow() < auctions[_tokenId].endTime, "NFTAuction.withdrawBid: Past auction end");

        uint256 previousBid = highestBid.bid;

        // Clean up the existing top bid
        delete highestBids[_tokenId];

        // Refund the top bidder
        _refundHighestBidder(_msgSender(), previousBid);

        emit BidWithdrawn(_tokenId, _msgSender(), previousBid);
    }

    /**
     @notice Results a finished auction
     @dev Only owner
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _tokenId Token ID of the NFT being auctioned
     */
    function resultAuction(uint256 _tokenId) external nonReentrant {
        
        // Check owner of the token is the creator and approved
        require(
            CyberSpawnNft.ownerOf(_tokenId) == _msgSender(),
            "NFTAuction.resultAuction: Not owner"
        );

        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_tokenId];
        
        // Check the auction real
        require(auction.endTime > 0, "NFTAuction.resultAuction: Auction does not exist");

        // Check the auction has ended
        require(_getNow() > auction.endTime, "NFTAuction.resultAuction: The auction has not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "NFTAuction.resultAuction: auction already resulted");

        // Ensure this contract is approved to move the token
        require(CyberSpawnNft.isApprovedForAll(_msgSender(), address(this)), "NFTAuction.resultAuction: auction not approved");

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_tokenId];
        address winner = highestBid.bidder;
        uint256 winningBid = highestBid.bid;
        uint256 maxShare = 1000;

        // Ensure auction not already resulted
        require(winningBid >= auction.reservePrice, "NFTAuction.resultAuction: reserve not reached");

        // Ensure there is a winner
        require(winner != address(0), "NFTAuction.resultAuction: no open bids");

        // Result the auction
        auctions[_tokenId].resulted = true;

        // Clean up the highest bid
        delete highestBids[_tokenId];


        // Work out platform fee from above reserve amount
        uint256 platformFeeInETH = winningBid.mul(platformFee).div(maxShare);

        // Send platform fee
        (bool platformTransferSuccess,) = platformFeeRecipient.call{value : platformFeeInETH}("");
        require(platformTransferSuccess, "NFTAuction.resultAuction: Failed to send platform fee");

        // Send remaining to creator
        (bool creatorTransferSuccess,) = CyberSpawnNft.ownerOf(_tokenId).call{value : winningBid.sub(platformFeeInETH)}("");
        require(creatorTransferSuccess, "NFTAuction.resultAuction: Failed to send the designer their royalties");

        // Transfer the token to the winner
        CyberSpawnNft.safeTransferFrom(CyberSpawnNft.ownerOf(_tokenId), winner, _tokenId);

        // // Remove auction and top bidder
        // delete auctions[_tokenId];

        emit AuctionResulted(_tokenId, winner, winningBid);
    }
    
    /**
     @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
     @dev Only owner
     @param _tokenId Token ID of the NFT being auctioned
     */
    function cancelAuction(uint256 _tokenId) external nonReentrant {
        // Check owner of the token is the creator and approved
        require(
            CyberSpawnNft.ownerOf(_tokenId) == _msgSender(),
            "NFTAuction.cancelAuction: Not owner"
        );

        // Check valid and not resulted
        Auction storage auction = auctions[_tokenId];

        // Check auction is real
        require(auction.endTime > 0, "NFTAuction.cancelAuction: Auction does not exist");

        // Check auction not already resulted
        require(!auction.resulted, "NFTAuction.cancelAuction: auction already resulted");

        // refund existing top bidder if found
        HighestBid storage highestBid = highestBids[_tokenId];
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(highestBid.bidder, highestBid.bid);

            // Clear up highest bid
            delete highestBids[_tokenId];
        }
        
        // Remove auction and top bidder
        delete auctions[_tokenId];

        emit AuctionCancelled(_tokenId);
    }

    /**
     @notice Update the current reserve price for an auction
     @dev Only owner
     @dev Auction must exist
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice New Ether reserve price (WEI value)
     */
    function updateAuctionReservePrice(uint256 _tokenId, uint256 _reservePrice) external {
        // Check owner of the token is the creator and approved
        require(
            CyberSpawnNft.ownerOf(_tokenId) == _msgSender(),
            "NFTAuction.updateAuctionReservePrice: Not owner"
        );

        require(
            auctions[_tokenId].endTime > 0,
            "NFTAuction.updateAuctionReservePrice: No Auction exists"
        );

        auctions[_tokenId].reservePrice = _reservePrice;
        emit UpdateAuctionReservePrice(_tokenId, _reservePrice);
    }

    /**
     @notice Update the current start time for an auction
     @dev Only owner
     @dev Auction must exist
     @param _tokenId Token ID of the NFT being auctioned
     @param _startTime New start time (unix epoch in seconds)
     */
    function updateAuctionStartTime(uint256 _tokenId, uint256 _startTime) external {
        // Check owner of the token is the creator and approved
        require(
            CyberSpawnNft.ownerOf(_tokenId) == _msgSender(),
            "NFTAuction.updateAuctionStartTime: Not owner"
        );

        require(
            auctions[_tokenId].endTime > 0,
            "NFTAuction.updateAuctionStartTime: No Auction exists"
        );

        auctions[_tokenId].startTime = _startTime;
        emit UpdateAuctionStartTime(_tokenId, _startTime);
    }

    /**
     @notice Update the current end time for an auction
     @dev Only owner
     @dev Auction must exist
     @param _tokenId Token ID of the NFT being auctioned
     @param _endTimestamp New end time (unix epoch in seconds)
     */
    function updateAuctionEndTime(uint256 _tokenId, uint256 _endTimestamp) external {
        // Check owner of the token is the creator and approved
        require(
            CyberSpawnNft.ownerOf(_tokenId) == _msgSender(),
            "NFTAuction.updateAuctionEndTime: Not owner"
        );
        require(
            auctions[_tokenId].endTime > 0,
            "NFTAuction.updateAuctionEndTime: No Auction exists"
        );
        require(
            auctions[_tokenId].startTime < _endTimestamp,
            "NFTAuction.updateAuctionEndTime: End time must be greater than start"
        );
        require(
            _endTimestamp > _getNow(),
            "NFTAuction.updateAuctionEndTime: End time passed. Nobody can bid"
        );

        auctions[_tokenId].endTime = _endTimestamp;
        emit UpdateAuctionEndTime(_tokenId, _endTimestamp);
    }

    //////////
    // Admin /
    //////////

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function toggleIsPaused() external {
        require(accessControls.hasAdminRole(_msgSender()), "NFTAuction.toggleIsPaused: Sender must be admin");
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     @notice Update the amount by which bids have to increase, across all auctions
     @dev Only admin
     @param _minBidIncrement New bid step in WEI
     */
    function updateMinBidIncrement(uint256 _minBidIncrement) external {
        require(accessControls.hasAdminRole(_msgSender()), "NFTAuction.updateMinBidIncrement: Sender must be admin");
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }


    /**
     @notice Method for updating the access controls contract used by the NFT
     @dev Only admin
     @param _accessControls Address of the new access controls contract (Cannot be zero address)
     */
    function updateAccessControls(CyberSpawnAccessControls _accessControls) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updateAccessControls: Sender must be admin"
        );

        require(address(_accessControls) != address(0), "NFTAuction.updateAccessControls: Zero Address");

        accessControls = _accessControls;
        emit UpdateAccessControls(address(_accessControls));
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updatePlatformFee: Sender must be admin"
        );

        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient) external {
        require(
            accessControls.hasAdminRole(_msgSender()),
            "NFTAuction.updatePlatformFeeRecipient: Sender must be admin"
        );

        require(_platformFeeRecipient != address(0), "NFTAuction.updatePlatformFeeRecipient: Zero address");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    ///////////////
    // Accessors //
    ///////////////

    /**
     @notice Method for getting all info about the auction
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getAuction(uint256 _tokenId)
    external
    view
    returns (uint256 _reservePrice, uint256 _startTime, uint256 _endTime, bool _resulted) {
        Auction storage auction = auctions[_tokenId];
        return (
        auction.reservePrice,
        auction.startTime,
        auction.endTime,
        auction.resulted
        );
    }

    /**
     @notice Method for getting all info about the highest bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getHighestBidder(uint256 _tokenId) external view returns (
        address payable _bidder,
        uint256 _bid,
        uint256 _lastBidTime
    ) {
        HighestBid storage highestBid = highestBids[_tokenId];
        return (
            highestBid.bidder,
            highestBid.bid,
            highestBid.lastBidTime
        );
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////
    
    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Private method doing the heavy lifting of creating an auction
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice NFT cannot be sold for less than this or minBidIncrement, whichever is higher
     @param _startTimestamp Unix epoch in seconds for the auction start time
     @param _endTimestamp Unix epoch in seconds for the auction end time.
     */
    function _createAuction(
        uint256 _tokenId,
        uint256 _reservePrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) private {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(auctions[_tokenId].endTime == 0, "NFTAuction.createAuction: Cannot relist");

        // Check end time not before start time and that end is in the future
        require(_endTimestamp > _startTimestamp, "NFTAuction.createAuction: End time must be greater than start");
        require(_endTimestamp > _getNow(), "NFTAuction.createAuction: End time passed. Nobody can bid.");

        // Setup the auction
        auctions[_tokenId] = Auction({
        reservePrice : _reservePrice,
        startTime : _startTimestamp,
        endTime : _endTimestamp,
        resulted : false
        });

        emit AuctionCreated(_tokenId);
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid Ether amount in WEI that the bidder sent when placing their bid
     */
    function _refundHighestBidder(address payable _currentHighestBidder, uint256 _currentHighestBid) private {
        // refund previous best (if bid exists)
        (bool successRefund,) = _currentHighestBidder.call{value : _currentHighestBid}("");
        require(successRefund, "NFTAuction._refundHighestBidder: failed to refund previous bidder");
        emit BidRefunded(_currentHighestBidder, _currentHighestBid);
    }
}