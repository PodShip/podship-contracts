// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "./PodShipErrors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

///// @title PodShip Podcast NFT
///// @author ABDul Rehman <devabdee@gmail.com>
///// @notice PodShip's main contract
contract PodShip is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    Counters.Counter private _podcastId;

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

    uint256 public constant MINIMUM_TIP = 1 * 10**18;
    mapping(uint256 => PodcastNFT) public podcastId;

    constructor() ERC721("PodShip Podcast NFT", "PODSHIP") {
        emit PodShipContractDeployed();
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
        if(msg.value <= MINIMUM_TIP){ revert PodShip__TippingLessThanOneMaticNotAllowed(); }
        (bool sent, ) = (podcastId[_podcastID].nftCreator).call{value: msg.value}("");
        if(!sent){ revert PodShip__FailedToSendMATIC(); }

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