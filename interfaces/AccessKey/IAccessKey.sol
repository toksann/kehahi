// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessKey {
    // 価格を記録する変数
    function price() external view returns (uint256);

    // 価格変動フラグ
    function priceFluctuations() external view returns (bool);

    // 予約情報確認用のアドレス
    function launchKey() external view returns (address);

    // ユーザー間取引の集計アドレス
    function tradeCounter() external view returns (address);

    // アクセスキーの発行
    function mint(address to, uint256 editionId) external;

    // アクセスキーの焼却
    function burn(address from) external;

    // 価格の設定
    function setPrice(uint256 newPrice) external;

    // 変動相場のON/OFF
    function fluctuateEnable() external;
    function fluctuateDisable(uint256 newPrice) external;

    // 保有者の入れ替え
    function swapHolder(address from, address to) external;

    // アクセスキーの分割
    function splitKey(uint256 splitRate) external;

    // ローンチ情報のアドレスの設定
    function setLaunchInfo(address _launchKey) external;

    // 価格の取得
    function getPrice() external view returns (uint256);

    // 価格変動フラグの取得
    function getPriceFluctuations() external view returns (bool);

    // ローンチ情報アドレスの取得
    function getLaunchKey() external view returns (address);

    // 取引集計アドレスの取得
    function getTradeCounter() external view returns (address);
}
