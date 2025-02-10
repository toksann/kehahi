// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILaunchKey {
    // イベント
    event SetLaunch(address indexed  _accessKey, uint256 indexed  _editionId, address indexed _launchOwner);
    event SetKeyPrice(address indexed  accessKey, uint256 indexed _editionId, address indexed _launchOwner, uint256 _keyPrice);
    event Reserve(address indexed _accessKey,uint256 indexed _editionId, address indexed reserver);
    event KeyLaunch(address indexed  accessKey, uint256 indexed editionId);
    event KeyRedeemed(address indexed redeemer);

    // ローンチを設定
    function setLaunch(address _accessKey, uint256 _editionId) external returns (bool);

    // 売出価格を設定
    function setKeyPrice(address _accessKey, uint256 _editionId, address _launchOwner, uint256 _keyPrice) external;

    // 予約者登録
    function reserve(address _accessKey, uint256 _editionId, address reserver) external;

    // ローンチ状態に変更
    function launch(address _accessKey, uint256 _editionId, address _launchOwner) external;

    // アクセスキー定価購入権を行使
    function redeemKey(address _accessKey, uint256 _editionId, address reserver) external;

    // ローンチ情報の問い合わせ
    function queryLaunch(address _accessKey, uint256 _editionId) external view returns(bool);
}
