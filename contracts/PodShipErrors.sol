// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// PodShip.sol:
error PodShip__TippingLessThanOneUsdNotAllowed();
error PodShip__FailedToSendMATIC();

// PodShipAuction.sol:
error PodShipAuction__OnlyNftOwnerCanStartTheAuction();
error PodShipAuction__AuctionDuration_1to7_DaysAllowed();
error PodShipAuction__NftRoyalties_1to50_PercentAllowed();
error PodShipAuction__ReservePriceZeroNotAllowed();
error PodShipAuction__NftNotOnAuction();
error PodShipAuction__AuctionEnded();
error PodShipAuction__OnlyNftOwnerAllowed();
error PodShipAuction__AuctionInProgress();
error PodShipAuction__InputAmountBelowNftReservePriceOrLastHighestBid();
error PodShipAuction__platformFeeTransferFailed();
error PodShipAuction__NftOwnerCutTransferFailed();
error PodShipAuction__AuctonWinnerCannotWithdraw();
error PodShipAuction__UserDidNotParticipatedInTheAuction();
error PodShipAuction__WithdrawFailed();
error PodShipAuction__OnlyAuctionCreatorAllowed();
error UpkeepNotNeeded(uint256 tippersLength, uint256 currentTime);