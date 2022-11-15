// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "./PodShipErrors.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

///// @notice PodShip Supporter NFT contract
contract PodShipSupporterNFT is ERC1155Supply, Ownable {

    uint8 public constant PodShipSupporterNft = 5;

    constructor() ERC1155("ipfs://QmYtVxCDyt7Mr12JDAgjhYS3wqq954n1sps8cjaJuW7RfL/") {}

    function mintPodShipSupporterNFT(address _winner) public {
        if(_winner == address(0)) { revert PodShip__ZeroAddress(); }
        _mint(_winner, PodShipSupporterNft, 1, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
        string(
            abi.encodePacked(
                super.uri(_id),
                Strings.toString(_id),
                ".json"
            )
        );
    }

}