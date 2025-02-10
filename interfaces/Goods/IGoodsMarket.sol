// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoodsMarket {
    // イベント
    event OpenShop(address indexed shopOwner, address indexed shopAddress);
    event CloseShop(address indexed shopOwner);
    event BuyGoods(address indexed buyer, address indexed shopOwner, uint256 indexed id, uint256 value);

    // グッズショップの紐づけ
    function openShop(address shopAddress) external;
    function closeShop() external;
    function getShopAddress(address shopOwner) external view returns (address);

    // 購入
    function buyGoods(address shopOwner, uint256 id, uint256 value) external;
}
