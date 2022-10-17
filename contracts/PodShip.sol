// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PodShip is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _nftId;
    Counters.Counter private _podcastId;

    struct PodcastNFT{
        address creator;
        address nftOwner;
        bool listed;
        uint256 nftId;
    }

    mapping(uint256 => PodcastNFT) public podcastId;

    constructor() ERC721("PodShip Podcast NFT", "PODSHIP") {}

    function mintNFT(string memory ipfsURI) public {

        _nftId.increment();
        _podcastId.increment();
        uint256 tokenId = _nftId.current();

        podcastId[_podcastId.current()] = PodcastNFT(
            msg.sender,
            msg.sender,
            false,
            tokenId
        );

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, ipfsURI);
    } 

    function tipCreator(uint256 _podcastID) public payable {
        require(msg.value >= 1 ether, "1 MATIC least allowed for tipping");
        (bool sent, ) = (podcastId[_podcastID].nftOwner).call{value: msg.value}("");
        require(sent, "Failed to send MATIC");
    }

}