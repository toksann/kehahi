// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/AccessKey/AccessKey.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {PerpetualKey} from "contracts/AccessKey/PerpetualKey/PerpetualKey.sol";

// アクセスキーのファクトリー(ownerは取引所)
contract KeyFactory is Ownable {
    using  Address for address;

    // SBT(ERC1155)のインスタンス
    PerpetualKey perpetualKey;

    // デプロイされたアクセスキーとSBTペアの配列
    mapping (address => uint256) public deployedKeyPairs;   // オーナー => SBT

    // デプロイされたアクセスキーとその権限保有者の配列
    mapping (address => address) public keyOwner;   // アクセスキー => オーナー

    constructor(string memory uri) Ownable(msg.sender) {
        perpetualKey = new PerpetualKey(uri);
    }

    // アクセスキーのデプロイ
    function createKey(
        string memory name,
        string memory symbol,
        bool priceFluctuations) public onlyOwner returns (address) {
        // 新しいアクセスキーをデプロイ
        AccessKey newKey = new AccessKey(name, symbol, priceFluctuations);
        // 対応するSBTのIDをペアリング
        deployedKeyPairs[address(newKey)] = uint256(uint160(address(newKey)));  // アクセスキーアドレスをID化する
        
        // デプロイしたアクセスキーをリストに追加
        keyOwner[address(newKey)] = msg.sender;
        
        return address(newKey);
    }

    // アクセスキーの焼却とSBTへの引き換え
    function perpetualizeKey(address keyAddress, address applicant, bytes memory data) public {
        // キーが存在しているか確認
        require(address(keyOwner[keyAddress]) != address(0), "An invalid access key address was specified.");
        uint256 _targetToken = deployedKeyPairs[keyAddress];    // 対応SBTのアドレスを取得
        require(_targetToken != 0);

        // keyAddressを焼却する
        AccessKey(keyAddress).burn(applicant);

        if(data.length > 0){
            // SBTをmintしてapplicantに与える
            perpetualKey.mint(applicant, uint256(uint160(address(keyAddress))), data);

            // applicantにExPointを付与する
            // ExPointのアドレスをもらっておいて、ここでmintする
        }
    }

   /* ******************************************** 
      AccessKey機能のラップ
   ******************************************** */

    // アクセスキーの変動相場を有効にする
    function fluctuateEnable(address keyAddress) external {
        AccessKey(keyAddress).fluctuateEnable();
    }

    // アクセスキーの変動相場を無効にする
    function fluctuateDisable(address keyAddress, uint256 newPrice) external {
        AccessKey(keyAddress).fluctuateDisable(newPrice);
    }

    // アクセスキーを分割する
    function splitKey(address keyAddress, uint256 splitRate) external {
        AccessKey(keyAddress).splitKey(splitRate);
    }
}
