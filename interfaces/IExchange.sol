// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange {
    // イベント
    event AccessKeyCreated(address indexed keyAddress, string name, string symbol, bool priceFluctuations);
    event AccessKeyPerpetual(address indexed keyAddress, address indexed applicant);
    event AccessKeyFluctuationEnabled(address indexed keyAddress);
    event AccessKeyFluctuationDisabled(address indexed keyAddress, uint256 newPrice);
    event AccessKeySplit(address indexed keyAddress, uint256 splitRate);
    event LaunchSet(address indexed accessKey, uint256 editionId);
    event KeyPriceSet(address indexed accessKey, uint256 editionId, address launchOwner, uint256 keyPrice);
    event AccessKeyReserved(address indexed accessKey, uint256 editionId, address indexed reserver);
    event AccessKeyLaunched(address indexed accessKey, uint256 editionId, address indexed launchOwner);
    event AccessKeyRedeemed(address indexed accessKey, uint256 editionId, address indexed reserver);
    event GoodsBought(address indexed shopOwner, uint256 id, uint256 value);

    // KeyFactory
    function createAccessKey(string memory name, string memory symbol, bool priceFluctuations) external returns (address);
    function perpetualizeKey(address keyAddress, address applicant, bytes memory data) external;
    function fluctuateEnable(address keyAddress) external;
    function fluctuateDisable(address keyAddress, uint256 newPrice) external;
    function splitKey(address keyAddress, uint256 splitRate) external;

    // LaunchKey
    function setLaunch(address _accessKey, uint256 _editionId) external returns(bool);
    function setKeyPrice(address _accessKey, uint256 _editionId, address _launchOwner, uint256 _keyPrice) external;
    function reserveAccessKey(address _accessKey, uint256 _editionId, address reserver) external;
    function launch(address _accessKey, uint256 _editionId, address _launchOwner) external;
    function redeemKey(address _accessKey, uint256 _editionId, address reserver) external;

    // GoodsMarket
    function buyGoods(address shopOwner, uint256 id, uint256 value) external;

    // その他
    function useService() external;
}
