// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "interfaces/Goods/IGoodsShop.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ExPoint} from "contracts/ExPoint/ExPoint.sol";
import "interfaces/Goods/IGoodsMarket.sol";

// グッズマーケットの実装(ownerは取引所)
contract GoodsMarket is IGoodsMarket {
    // グッズ購入で支払いに利用できるトークン
    address private paymentPoint;

    // オーナーとグッズショップの紐づけ
    mapping(address => address) private shops;

    constructor(address _paymentPoint){
        paymentPoint = _paymentPoint;
    }

    // 開店
    function openShop(address shopAddress) public {
        require(getShopAddress(msg.sender) == address(0));  // senderにショップが紐づけられていないか確認
        shops[msg.sender] = shopAddress;
        emit OpenShop(msg.sender, shopAddress);
    }

    // 閉店
    function closeShop() public {
        require(getShopAddress(msg.sender) != address(0));  // senderにショップが紐づけられているか確認
        delete shops[msg.sender];
        emit CloseShop(msg.sender);
    }

    // グッズショップのアドレスを取得
    function getShopAddress(address shopOwner) public view returns (address) {
        return shops[shopOwner];
    }

    // 購入
    function buyGoods(address shopOwner, uint256 id, uint256 value) public  {
        // 残高確認
        require(ExPoint(paymentPoint).balanceOf(msg.sender) >= IGoodsShop(shops[shopOwner]).getGoodsPrice(id), "You cannot purchase with your current balance.");

        // 購入者にmint
        require(IGoodsShop(shops[shopOwner]).buyGoods(id, value), "You failed to purchase the goods.");

        // 購入者からshopOwnerにPriceぶんのExPointを送る
        ExPoint(paymentPoint).transferFrom(msg.sender, shopOwner, IGoodsShop(shops[shopOwner]).getGoodsPrice(id));

        emit BuyGoods(msg.sender, shopOwner, id, value);
    }
}