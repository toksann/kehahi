// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "interfaces/AccessKey/IAccessKey.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "interfaces/AccessKey/ILaunchKey.sol";

// アクセスキーを売り出す処理(ownerは取引所)
contract LaunchKey is ILaunchKey, Ownable {
    using  Address for address;
    // 支払い用トークン
    address public immutable paymentToken;

    // ローンチ情報構造体
    struct LaunchData {
        address launchOwner;                        // アクセスキー発行希望者
        bool isLaunched;                            // ローンチ済フラグ
        uint256 keyPrice;                           // アクセスキーの予定販売価格
        mapping (address => uint256) reservations;  //　このアクセスキーの予約者リスト
    }

    // アクセスキーと発行弾数ごとのローンチ情報
    mapping (address => mapping (uint256 => LaunchData)) private launchInfo;   // アクセスキーアドレス => 第n弾 => ローンチ情報

    constructor(address _paymentToken) Ownable(msg.sender) {
        paymentToken = _paymentToken;
    }

    // ローンチを設定
    function setLaunch(address _accessKey, uint256 _editionId) public  returns (bool) {
        require(launchInfo[_accessKey][_editionId].launchOwner == address(0),
         "This launch information has already been registered by another launchOwner address");
        
        launchInfo[_accessKey][_editionId].launchOwner = msg.sender;
        launchInfo[_accessKey][_editionId].isLaunched = false;
        launchInfo[_accessKey][_editionId].keyPrice= 0;

        // 初期発行でない場合は、手数料を徴収する
        if(IAccessKey(_accessKey).launchKey() != address(0)) {
            // 手数料(ExPoint)を徴収する
        } else{
            // 初期発行時にlaunchKeyのアドレスを与える
            IAccessKey(_accessKey).setLaunchInfo(address(this));
        }

        emit SetLaunch(_accessKey, _editionId, msg.sender);
        return true;
    }

    // 売出価格を設定
    function setKeyPrice(address _accessKey, uint256 _editionId, address _launchOwner, uint256 _keyPrice) public  {
        require(launchInfo[_accessKey][_editionId].launchOwner == _launchOwner, "The launchOwner information does not match");
        launchInfo[_accessKey][_editionId].keyPrice = _keyPrice;

        // 初期発行時のみAccessKeyの価格をローンチ価格に合わせ、初期売り出し価格とする
        if(_editionId == 0){
            IAccessKey(_accessKey).setPrice(_keyPrice);
        }

        emit SetKeyPrice(_accessKey, _editionId, _launchOwner, _keyPrice);
    }

    // 予約者登録
    function reserve(address _accessKey, uint256 _editionId, address reserver) public {
        require(!launchInfo[_accessKey][_editionId].isLaunched, "Launch has already occurred");
        require(launchInfo[_accessKey][_editionId].reservations[reserver] == 0, "You have already reserved a key");
        launchInfo[_accessKey][_editionId].reservations[reserver] = 1;

        emit Reserve(_accessKey, _editionId, reserver);
    }

    // ローンチ状態に変更
    function launch(address _accessKey, uint256 _editionId, address _launchOwner) public  {
        require(launchInfo[_accessKey][_editionId].launchOwner == _launchOwner, "The launchOwner information does not match");
        require(!launchInfo[_accessKey][_editionId].isLaunched, "Launch has already occurred");
        launchInfo[_accessKey][_editionId].isLaunched = true;

        emit KeyLaunch(_accessKey, _editionId);
    }

    // アクセスキー定価購入権を行使
    function redeemKey(address _accessKey, uint256 _editionId, address reserver) public {
        require(launchInfo[_accessKey][_editionId].isLaunched, "Launch has not occurred yet");
        require(launchInfo[_accessKey][_editionId].reservations[reserver] >= 1, "You have not reserved a key");

        // アクセスキーの価格分のトークンを転送
        IERC20(paymentToken).transferFrom(reserver, launchInfo[_accessKey][_editionId].launchOwner, launchInfo[_accessKey][_editionId].keyPrice);

        // アクセスキーをmint
        bytes memory funcMint = abi.encodeWithSignature("mint(address)", reserver);
        bytes memory returnData = address(_accessKey).functionCall(funcMint);   // mintを呼びだす
        require(returnData.length == 0, "Unexpected return data");

        // 予約者のマップを削除
        delete launchInfo[_accessKey][_editionId].reservations[reserver];

        emit KeyRedeemed(reserver);
    }

    // ローンチ情報の問い合わせ
    function queryLaunch(address _accessKey, uint256 _editionId) public view returns(bool) {
        bool result = launchInfo[_accessKey][_editionId].reservations[msg.sender] == 1;
        return result;
    }
}