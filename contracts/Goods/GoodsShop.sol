// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/Goods/Goods.sol";
import "interfaces/Goods/IGoodsMarket.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "interfaces/Goods/IGoodsShop.sol";

// グッズショップの実装(ownerはパブリッシャー)
contract GoodsShop is IGoodsShop, Ownable {
    using Address for address;

    address private marketAddress;
    Goods private goods;

    // 販売関連情報
    struct SaleStatus {
        bool isBuyable; // 購入可能状態
        uint256 limitBuyableCount;  // 購入回数制限
    }
    mapping (uint256 => SaleStatus) private goodsStatus;    // idごとの販売関連情報
    mapping (address => mapping (uint256 => uint256)) private buyerData;   // 購入者情報(buyerアドレス=>id=>購入回数)

    constructor(string memory uri) Ownable(msg.sender) {
        goods = new Goods(uri, msg.sender);
    }

    /* ******************************************** 
      グッズマーケットとの連携
   ******************************************** */
    // グッズマーケットのアドレス取得確認
    function setMarketAddress(address _marketAddress) external {
        marketAddress = _marketAddress;
    }

    // グッズマーケットに開店を申告
    function openShop() external {
        IGoodsMarket(marketAddress).openShop(address(this));
    }

    // グッズマーケットに閉店を申告    
    function closeShop() external {
        IGoodsMarket(marketAddress).closeShop();
    }

    // グッズの購入
    function buyGoods(uint256 id, uint256 value) public checkMarket returns(bool) {
        bool success = false;
        // 過去に購入回数制限以上に購入した記録が無いことを確認
        require(buyerData[msg.sender][id] < goodsStatus[id].limitBuyableCount, "You have exceeded the number of purchases allowed!");

        goods.mint(msg.sender, id, value);
        buyerData[msg.sender][id] += 1;

        success = true;
        return success;
    }

    /* ******************************************** 
      販売関連情報の制御
   ******************************************** */
    // 購入'可能状態'の変更
    function setGoodsBuyable(uint256 id, bool isBuyable) public onlyOwner checkMarket {
        goodsStatus[id].isBuyable = isBuyable;
        emit SetGoodsBuyable(id, isBuyable);
    }

    // 購入'回数制限'の変更
    function setGoodsBuyLimit(uint256 id, uint256 limitBuyableCount) public onlyOwner checkMarket {
        goodsStatus[id].limitBuyableCount = limitBuyableCount;
        emit SetGoodsBuyLimit(id, limitBuyableCount);
    }

    // 購入'回数制限'の追加
    function addGoodsBuyLimit(uint256 id, uint256 addBuyableCount) public onlyOwner checkMarket {
        goodsStatus[id].limitBuyableCount += addBuyableCount;
        emit AddGoodsBuyLimit(id, addBuyableCount);
    }

    // 購入'可能状態'の変更をまとめて実行
    function setMultiGoodsBuyable(uint256[] memory ids, bool isBuyable) public onlyOwner checkMarket {
        for (uint256 i = 0; i < ids.length; i++) {
            setGoodsBuyable(ids[i], isBuyable);
        }
    }

    // 購入'回数制限'の変更をまとめて実行
    function setMultiGoodsBuyLimit(uint256[] memory ids, uint256 limitBuyableCount) public onlyOwner checkMarket {
        for (uint256 i = 0; i < ids.length; i++) {
            setGoodsBuyLimit(ids[i], limitBuyableCount);
        }
    }

    // 購入'回数制限'の追加をまとめて実行
    function addMultiGoodsBuyLimit(uint256[] memory ids, uint256 addBuyableCount) public onlyOwner checkMarket {
        for (uint256 i = 0; i < ids.length; i++) {
            addGoodsBuyLimit(ids[i], addBuyableCount);
        }
    }


    /* ******************************************** 
      ショップの機能(Goodsとの連携)
   ******************************************** */
    // グッズを登録
    function registerGoods(
        uint256 id,
        string memory name,
        string memory description,
        uint256 supply,
        uint256 buyLimit,
        uint256 price,
        bytes memory data,
        uint256 limitBuyableCount
    ) public onlyOwner checkMarket {
        // グッズを生成
        goods.createGoods(
            id,
            name,
            description,
            supply,
            buyLimit,
            price,
            data
        );
        // 販売状態を設定
        goodsStatus[id] = SaleStatus(
            false,
            limitBuyableCount
        );
        emit RegisterGoods(id, name, description, supply, buyLimit, price, data, limitBuyableCount);
    }

    // 価格の取得
    function getGoodsPrice(uint256 id) public checkMarket view returns (uint256) {
        return goods.getPrice(id);
    }

    // 価格の設定
    function setGoodsPrice(uint256 id, uint256 newPrice) public onlyOwner checkMarket {
        goods.setPrice(id, newPrice);
        emit SetGoodsPrice(id, newPrice);
    }

    // グッズストックの追加
    function addGoods(uint256 id, uint256 amount) public checkMarket {
        goods.addStock(id, amount);
        emit AddGoods(id, amount);
    }

    // 関数修飾子： 取引所アドレスの取得済確認
   modifier checkMarket(){
      require(marketAddress != address(0), "Exchange address not obtained!");
      _;
   }
}