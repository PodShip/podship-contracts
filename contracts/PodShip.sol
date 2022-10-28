// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PodShip is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
    Counters.Counter private _podcastId;

    struct PodcastNFT{
        address nftCreator;
        address nftOwner;
        bool listed;
        uint256 tokenId;
    }

    mapping(uint256 => PodcastNFT) public podcastId;

    constructor() ERC721("PodShip Podcast NFT", "PODSHIP") {}

    function mintNFT(string memory ipfsURI) external {

        _tokenId.increment();
        _podcastId.increment();
        uint256 token_Id = _tokenId.current();

        podcastId[_podcastId.current()] = PodcastNFT(
            msg.sender,
            msg.sender,
            false,
            token_Id
        );

        _safeMint(msg.sender, token_Id);
        _setTokenURI(token_Id, ipfsURI);
    } 

    function tipCreator(uint256 _podcastID) external payable {
        require(msg.value >= 1 ether, "1 MATIC least allowed for tipping");
        (bool sent, ) = (podcastId[_podcastID].nftCreator).call{value: msg.value}("");
        require(sent, "Failed to send MATIC");
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