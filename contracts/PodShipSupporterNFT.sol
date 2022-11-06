// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract PodShipSupporterNFT is ERC1155Supply {

    uint8 public constant PodShipSupporterNft = 5;

    constructor() ERC1155("ipfs://QmYtVxCDyt7Mr12JDAgjhYS3wqq954n1sps8cjaJuW7RfL/") {}

    function mintPodShipSupporterNFT(address _winner) public {
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