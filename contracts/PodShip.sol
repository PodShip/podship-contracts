// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PodShipErrors.sol";
import "./PriceConverter.sol";
import "./PodShipSupporterNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PodShip is ERC721URIStorage, Ownable {
    using PriceConverter for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    Counters.Counter private _podcastId;
    PodShipSupporterNFT public podshipNft;

    struct PodcastNFT {
        address nftCreator;
        address nftOwner;
        uint256 tokenId;
    }

    event PodShipContractDeployed();
    event ProdcastCreated(
        string indexed IPFSUri,
        address indexed nftCreator,
        uint256 indexed tokenId
    );
    event Tipping(
        uint256 indexed podcastId,
        uint256 indexed tip,
        address indexed supporter
    );

    address[] public tippers;
    // uint256 public constant minimumTip = 1 * 10**18; ///// For Mainnet
    uint256 public constant minimumTip = 1 * 10**17; ///// For Testnet/Testing
    mapping(uint256 => PodcastNFT) public podcastId;

    constructor(address _podshipNft) ERC721("PodShip Podcast NFT", "PODSHIP") {
        podshipNft = PodShipSupporterNFT(_podshipNft);
        emit PodShipContractDeployed();
    }

    function mintPodShipSupporterNFT(address _winner) public {
        podshipNft.mintPodShipSupporterNFT(_winner);
    }

    function mintNFT(string memory ipfsURI) external returns(uint256) {
        _tokenId.increment();
        _podcastId.increment();
        uint256 token_Id = _tokenId.current();
        podcastId[_podcastId.current()] = PodcastNFT(
            msg.sender,
            msg.sender,
            token_Id
        );
        _safeMint(msg.sender, token_Id);
        _setTokenURI(token_Id, ipfsURI);

        emit ProdcastCreated(ipfsURI, msg.sender, token_Id);
        return token_Id;
    } 

    function tipCreator(uint256 _podcastID) external payable {
        if(msg.value.getConversionRate() < minimumTip){ revert PodShip__TippingLessThanOneUsdNotAllowed(); }
        (bool sent, ) = (podcastId[_podcastID].nftCreator).call{value: msg.value}("");
        if(!sent){ revert PodShip__FailedToSendMATIC(); }

        tippers.push(msg.sender);
        emit Tipping(_podcastID, msg.value, msg.sender);
    }

    function getNftCreator(uint256 _podcastID) public view returns(address) {
        return podcastId[_podcastID].nftCreator;
    }

    function getNftOwner(uint256 _podcastID) public view returns(address) {
        return podcastId[_podcastID].nftOwner;
    }

    function getNftTokenId(uint256 _podcastID) public view returns(uint256) {
        return podcastId[_podcastID].tokenId;
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenId.current();
    }
    
}