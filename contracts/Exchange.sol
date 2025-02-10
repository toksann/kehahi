// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 取引所が扱う資産を管理する処理

/* ************************************

ここに各機能のインスタンスを生成する
・ExPoint
   ・取引所で利用されるインセンティブ
・KeyFactory
   ・クリエイターが任意にこれを通してAccessKeyをデプロイする
・LaunchKey
   ・クリエイターが任意にこれを通してAccessKeyを販売する
・GoodsMarket
   ・クリエイターが任意にこれを通してGoodsShopを開き操作する
・(テスト版機能のみ)取引所専用通貨のインスタンスを生成し、配布や発行等を管理する。

************************************ */

// その他必要な処理
// ・サービス手数料(ExCurrency)がいくらかを設定する
// ・サービス手数料(ExPoint)がいくらかを設定する
// ・インセンティブ配布量(ExPoint)がいくらかを設定しする
// ・回収したExPointの一部もしくは全部をburnする

import "@openzeppelin/contracts/access/Ownable.sol";
import {ExPoint} from "contracts/ExPoint/ExPoint.sol";
import {KeyFactory} from "contracts/AccessKey/KeyFactory.sol";
import {LaunchKey} from "contracts/AccessKey/LaunchKey.sol";
import {GoodsMarket} from "contracts/Goods/GoodsMarket.sol";
import {ExCurrency} from "contracts/ExCurrency/ExCurrency.sol";
import "interfaces/IExchange.sol";

contract Exchange is IExchange, Ownable {
   // 取引所機能を構成するインスタンスのアドレス
   address private exPoint;
   address private keyFactory;
   address private launchKey;
   address private goodsMarket;
   address private exCurrency;

   constructor(uint256 _exCurrencySupply, uint256 _exPointSupply, string memory _uriSBT) Ownable(msg.sender) {
      // テスト通貨を設定
      exCurrency = address(new ExCurrency(_exCurrencySupply));

      // 取引所機能を構成するインスタンスを作成
      exPoint = address(new ExPoint(_exPointSupply));
      keyFactory = address(new KeyFactory(_uriSBT));
      launchKey = address(new LaunchKey(exCurrency));
      goodsMarket = address(new GoodsMarket(exPoint));
   }

   /* ******************************************** 
      KeyFactory
   ******************************************** */
   // アクセスキーの作成
   function createAccessKey(
        string memory name,
        string memory symbol,
        bool priceFluctuations) external returns (address){
      address newKey = KeyFactory(keyFactory).createKey(name, symbol, priceFluctuations);

      emit AccessKeyCreated(newKey, name, symbol, priceFluctuations);
      return  newKey;
   }

   // アクセスキーの焼却とSBTへの交換
   function perpetualizeKey(address keyAddress, address applicant, bytes memory data) external {
      KeyFactory(keyFactory).perpetualizeKey(keyAddress, applicant, data);

      emit AccessKeyPerpetual(keyAddress, applicant);
   }

   // アクセスキーの変動相場を有効にする
    function fluctuateEnable(address keyAddress) external {
        KeyFactory(keyFactory).fluctuateEnable(keyAddress);

        emit AccessKeyFluctuationEnabled(keyAddress);
    }

    // アクセスキーの変動相場を無効にする
    function fluctuateDisable(address keyAddress, uint256 newPrice) external {
        KeyFactory(keyFactory).fluctuateDisable(keyAddress, newPrice);

        emit AccessKeyFluctuationDisabled(keyAddress, newPrice);
    }

    // アクセスキーを分割する
    function splitKey(address keyAddress, uint256 splitRate) external {
        KeyFactory(keyFactory).splitKey(keyAddress, splitRate);

        emit AccessKeySplit(keyAddress, splitRate);
    }

   /* ******************************************** 
      LaunchKey
   ******************************************** */
   // アクセスキーのローンチを設定
   function setLaunch(address _accessKey, uint256 _editionId) external returns(bool){
      bool success = LaunchKey(launchKey).setLaunch(_accessKey, _editionId);

      emit LaunchSet(_accessKey, _editionId);
      return success;
   }

   // アクセスキーの価格設定
   function setKeyPrice(address _accessKey, uint256 _editionId, address _launchOwner, uint256 _keyPrice) external {
      LaunchKey(launchKey).setKeyPrice(_accessKey, _editionId, _launchOwner, _keyPrice);

      emit KeyPriceSet(_accessKey, _editionId, _launchOwner, _keyPrice);
   }

   // アクセスキーの予約
   function reserveAccessKey(address _accessKey, uint256 _editionId, address reserver) external {
      LaunchKey(launchKey).reserve(_accessKey, _editionId, reserver);

      emit AccessKeyReserved(_accessKey, _editionId, reserver);
   }

   // アクセスキーの本ローンチ
   function launch(address _accessKey, uint256 _editionId, address _launchOwner) external {
      LaunchKey(launchKey).launch(_accessKey, _editionId, _launchOwner);

      emit AccessKeyLaunched(_accessKey, _editionId, _launchOwner);
   }

   // 予約したアクセスキーの引き換え
   function redeemKey(address _accessKey, uint256 _editionId, address reserver) external {
      LaunchKey(launchKey).redeemKey(_accessKey, _editionId, reserver);

      emit AccessKeyRedeemed(_accessKey, _editionId, reserver);
   }

   /* ******************************************** 
      GoodsMarket
   ******************************************** */
   // グッズの購入
   function buyGoods(address shopOwner, uint256 id, uint256 value) external {
      GoodsMarket(goodsMarket).buyGoods(shopOwner, id, value);

      emit GoodsBought(shopOwner, id, value);
   }

   /* ******************************************** 
      その他
   ******************************************** */
   // サービスの利用
   function useService() external {
   }
}