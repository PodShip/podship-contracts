// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice() internal view returns (uint256) {

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 maticAmount)
        internal
        view
        returns (uint256)
    {
        uint256 maticPrice = getPrice();
        uint256 maticAmountInUsd = (maticPrice * maticAmount) / 1000000000000000000;
        return maticAmountInUsd;
    }
}