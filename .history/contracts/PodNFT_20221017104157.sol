pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CyberSpawnNFT is ERC721 {

  uint256 tokenId;

  constructor() ERC721("PodShipNFT", "PodNFT") public {}
    // podcast type: A - Audio & AV - Audio Video

  function mint(address recipient, uint8 _podcastType, string memory podcastURI) external returns (uint256) {
    tokenId = tokenId + 1;
    _mint(recipient, tokenId);

    return tokenId;
  }
  
}