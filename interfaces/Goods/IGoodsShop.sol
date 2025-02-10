// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoodsShop {
    // イベント
    event SetGoodsBuyable(uint256 indexed id, bool isBuyable);
    event SetGoodsBuyLimit(uint256 indexed id, uint256 limitBuyableCount);
    event AddGoodsBuyLimit(uint256 indexed id, uint256 addBuyableCount);
    event RegisterGoods(
        uint256 indexed id,
        string name,
        string description,
        uint256 supply,
        uint256 buyLimit,
        uint256 price,
        bytes data,
        uint256 limitBuyableCount
    );
    event SetGoodsPrice(uint256 indexed id, uint256 newPrice);
    event AddGoods(uint256 indexed id, uint256 amount);

    // グッズマーケットとの連携
    function setMarketAddress(address _marketAddress) external;
    function openShop() external;
    function closeShop() external;
    function buyGoods(uint256 id, uint256 value) external returns(bool);

    // 販売関連情報の制御
    function setGoodsBuyable(uint256 id, bool isBuyable) external;
    function setGoodsBuyLimit(uint256 id, uint256 limitBuyableCount) external;
    function addGoodsBuyLimit(uint256 id, uint256 addBuyableCount) external;
    function setMultiGoodsBuyable(uint256[] memory ids, bool isBuyable) external;
    function setMultiGoodsBuyLimit(uint256[] memory ids, uint256 limitBuyableCount) external;
    function addMultiGoodsBuyLimit(uint256[] memory ids, uint256 addBuyableCount) external;

    // ショップの機能(Goodsとの連携)
    function registerGoods(
        uint256 id,
        string memory name,
        string memory description,
        uint256 supply,
        uint256 buyLimit,
        uint256 price,
        bytes memory data,
        uint256 limitBuyableCount
    ) external;
    function getGoodsPrice(uint256 id) external view returns (uint256);
    function setGoodsPrice(uint256 id, uint256 newPrice) external;
    function addGoods(uint256 id, uint256 amount) external;
}
