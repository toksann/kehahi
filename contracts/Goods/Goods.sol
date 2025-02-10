// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// グッズの実装(ownerはパブリッシャー)
contract Goods is ERC1155 {

    struct GoodsInfo {
        string name;    // 名称
        string description; // 説明
        uint256 supply; // 供給量(これが0のときは無制限販売、それ以上のときはその数量限定販売になる)
        uint256 stock;  // 在庫
        uint256 buyLimit;   // 一回あたりの購入制限
        uint256 price;  // 価格
        bytes data;    // メタデータ

        mapping (address => uint256) buyers;
    }
    mapping(uint256 => GoodsInfo) public goodsInfo;

    constructor(string memory uri, address initialOwner) ERC1155(uri){}

    // グッズを生成
    function createGoods(
        uint256 id,
        string memory name,
        string memory description,
        uint256 supply,
        uint256 buyLimit,
        uint256 price,
        bytes memory data
    ) public {
        goodsInfo[id].name = name;
        goodsInfo[id].description = description;
        goodsInfo[id].supply = supply;
        goodsInfo[id].stock = supply;    // 初期設定時はstock = supplyなので、どちらもsupplyを設定
        goodsInfo[id].buyLimit = buyLimit;
        goodsInfo[id].price = price;
        goodsInfo[id].data = data;

    }

    // 価格の取得
    function getPrice(uint256 _id) public view returns (uint256) {
        return  goodsInfo[_id].price;
    }

    // 価格の設定
    function setPrice(uint256 _id, uint256 _price) public  {
        goodsInfo[_id].price = _price;
    }

    // 発行(販売状態による制限を含む)
    function mint(address to, uint256 id, uint256 value) public {
        require(value <= goodsInfo[id].buyLimit, "The purchase quantity exceeds the purchase limit.");  // 制限以上には買わせない

        // 数量限定販売のとき、売り切れてたら買えない
        if(goodsInfo[id].supply > 0 && goodsInfo[id].stock <= 0){
            revert("The goods are sold out.");
        }
        _mint(to, id, value, goodsInfo[id].data);

        // 数量限定販売のとき、在庫を減らす
        if(goodsInfo[id].supply > 0){
            goodsInfo[id].stock--;
        }
    }

    // 在庫の追加
    function addStock(uint256 id, uint256 amount) public {
        require(goodsInfo[id].supply > 0, "This item is set for unlimited sale.");
        goodsInfo[id].supply += amount;
        goodsInfo[id].stock += amount;
    }
}
