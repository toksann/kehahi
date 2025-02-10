// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************

   このコントラクトは外部から取引所の機能にアクセスするものです。
   アカウントごとにインスタンスを生成することが前提です。

*************************************************/
import "@openzeppelin/contracts/access/Ownable.sol";
import "interfaces/IExchange.sol";

contract ExAccount is Ownable {
   // Exchangeコントラクトのアドレス
   address exchangeAddress;

   bool isCreateAccessKey; // アクセスキーの作成経験があるかを示すフラグ

   // 機能フラグ
   uint16 private userFunctionFrags = 0;      // 非クリエイター向け機能の有効化/無効化を設定する
   uint16 private creatorFunctionFrags = 0;      // クリエイター向け機能の有効化/無効化を設定する
   
   // 機能フラグ：非クリエイター向け機能
   enum Users {
      PerpetualizeKey,
      ReserveAccessKey,
      RedeemKey,
      BuyGoods
   }
   
   // 機能フラグ：クリエイター向け機能
   enum Creators {
      CreateAccessKey,
      FluctuateEnable,
      FluctuateDisable,
      SplitKey,
      SetLaunch,
      SetKeyPrice,
      Launch,
      UseService
   }

   bool isBANUser = false;  // 非クリエイター向け機能BANフラグ
   bool isBANCreator = false;  // クリエイター向け機能BANフラグ

   constructor() Ownable(msg.sender) {
      userFunctionFragEnable();   // 非クリエイター向け機能をデフォルトで利用可能にする
      createAccessKeyAllow(); // アクセスキーの作成機能のみ利用可能にしておく
      isBANUser = false;
      isBANCreator = false;
      isCreateAccessKey = false;
   }

   // 取引所アドレスの取得
   function setExchangeAddress(address _exchangeAddress) external {
      exchangeAddress = _exchangeAddress;
   }

   /* ******************************************** 
      機能フラグ制御
   ******************************************** */
   // 非クリエイター機能フラグの有効化
   function setUserFunctionFrag(Users _frags) private {
      require(isBANUser, "You are prohibited from using the user function.");
      userFunctionFrags |= uint16(1 << uint16(_frags));
   }

   // 非クリエイター機能フラグの無効化
   function clearUserFunctionFrag(Users _frags) private {
      require(isBANUser, "You are prohibited from using the user function.");
      userFunctionFrags &= ~uint16(1 << uint16(_frags));
   }

   // クリエイター機能フラグの有効化
   function setCreatorFunctionFrag(Creators _frags) private {
      require(isBANCreator, "You are prohibited from using the creator function.");
      creatorFunctionFrags |= uint16(1 << uint16(_frags));
   }

   // クリエイター機能フラグの無効化
   function clearCreatorFunctionFrag(Creators _frags) private {
      require(isBANCreator, "You are prohibited from using the creator function.");
      creatorFunctionFrags &= ~uint16(1 << uint16(_frags));
   }

   // 非クリエイター機能フラグをまとめて有効化にする
   function userFunctionFragEnable() private {
      userFunctionFrags |= uint16(1 << (uint16(type(Users).max) + 1)) - 1;
   }

   // 非クリエイター機能フラグをまとめて無効化にする
   function userFunctionFragDisable(bool ban) external  {
      require(msg.sender != owner(), "You are a party involved.");
      userFunctionFrags &= 0;

      if(ban) isBANUser = true;
   }

   // クリエイター機能フラグをまとめて有効化にする
   function creatorFunctionFragEnable() private {
      creatorFunctionFrags |= uint16(1 << (uint16(type(Creators).max) + 1)) - 1;
   }

   // クリエイター機能フラグをまとめて無効化にする
   function creatorFunctionFragDisable(bool ban) external  {
      require(msg.sender != owner(), "You are a party involved.");
      creatorFunctionFrags &= 0;

      if(ban) isBANCreator = true;
   }

   // アクセスキー作成機能の解放(これが実行されないとその他の機能の利用に支障をきたす)
   function createAccessKeyAllow() private {
      // オーナー外が権限を与えるかは一旦考える
      setCreatorFunctionFrag(Creators.CreateAccessKey);
   }

   // 非クリエイター向け機能BANの解除
   function clearBANUser() external {
      require(msg.sender != owner(), "You are the user.");
      userFunctionFragEnable();
      isBANUser = false;
   }

   // クリエイター向け機能BANの解除
   function clearBANCreator() external {
      require(msg.sender != owner(), "You are the creator.");

      if(isCreateAccessKey) {  // アクセスキー作成経験がある場合
         // すべてのクリエイター向け機能を解放する
         creatorFunctionFragEnable();
      } else {                 // アクセスキー作成経験が無い場合
         // アクセスキー作成機能のみ解放する
         createAccessKeyAllow();
      }
      isBANCreator = false;
   }

   /* ******************************************** 
      非クリエイター向け機能
   ******************************************** */
   // アクセスキーの焼却とSBTへの交換
   function perpetualizeKey(address keyAddress, bytes memory data) external onlyOwner checkExchange checkNormalUser(Users.PerpetualizeKey) {
      IExchange(exchangeAddress).perpetualizeKey(keyAddress, msg.sender, data);
   }

   // アクセスキーの予約
   function reserveAccessKey(address _accessKey, uint256 _editionId) external onlyOwner checkExchange checkNormalUser(Users.ReserveAccessKey) {
      IExchange(exchangeAddress).reserveAccessKey(_accessKey, _editionId, msg.sender);
   }

   // 予約したアクセスキーの引き換え
   function redeemKey(address _accessKey, uint256 _editionId) external onlyOwner checkExchange checkNormalUser(Users.RedeemKey) {
      IExchange(exchangeAddress).redeemKey(_accessKey, _editionId, msg.sender);
   }

   // グッズの購入
   function buyGoods(address shopOwner, uint256 id, uint256 value) external onlyOwner checkExchange checkNormalUser(Users.BuyGoods) {
      IExchange(exchangeAddress).buyGoods(shopOwner, id, value);
   }

   /* ******************************************** 
      クリエイター向け機能
   ******************************************** */
   // アクセスキーの作成
   function createAccessKey(string memory name, string memory symbol, bool priceFluctuations) external onlyOwner checkExchange checkNormalCreator(Creators.CreateAccessKey) returns(address) {
      address newKey = IExchange(exchangeAddress).createAccessKey(name, symbol, priceFluctuations);
      require(newKey != address(0), "Failed to create access key.");

      creatorFunctionFragEnable();   // アクセスキー作成によって他のクリエイター向け機能も解放する
      isCreateAccessKey = true;
      return newKey;
   }

   // アクセスキーの変動相場を有効にする
    function fluctuateEnable(address keyAddress) external onlyOwner checkExchange checkNormalCreator(Creators.FluctuateEnable) {
        IExchange(exchangeAddress).fluctuateEnable(keyAddress);
    }

    // アクセスキーの変動相場を無効にする
    function fluctuateDisable(address keyAddress, uint256 newPrice) external onlyOwner checkExchange checkNormalCreator(Creators.FluctuateDisable) {
        IExchange(exchangeAddress).fluctuateDisable(keyAddress, newPrice);
    }

    // アクセスキーを分割する
    function splitKey(address keyAddress, uint256 splitRate) external onlyOwner checkExchange checkNormalCreator(Creators.SplitKey) {
        IExchange(exchangeAddress).splitKey(keyAddress, splitRate);
    }

   // アクセスキーのローンチを設定
   function setLaunch(address _accessKey, uint256 _editionId) external onlyOwner checkExchange checkNormalCreator(Creators.SetLaunch) returns(bool) {
      bool success = IExchange(exchangeAddress).setLaunch(_accessKey, _editionId);
      return success;
   }

   // アクセスキーの価格設定
   function setKeyPrice(address _accessKey, uint256 _editionId, uint256 _keyPrice) external onlyOwner checkExchange checkNormalCreator(Creators.SetKeyPrice) {
      IExchange(exchangeAddress).setKeyPrice(_accessKey, _editionId, msg.sender, _keyPrice);
   }

   // アクセスキーの本ローンチ
   function launch(address _accessKey, uint256 _editionId) external onlyOwner checkExchange checkNormalCreator(Creators.Launch) {
      IExchange(exchangeAddress).launch(_accessKey, _editionId, msg.sender);
   }

   // サービスの利用
   function useService() external onlyOwner checkExchange checkNormalCreator(Creators.UseService) {
      IExchange(exchangeAddress).useService();
   }

   /* ******************************************** 
      関数修飾子
   ******************************************** */
   // 取引所アドレスの取得済確認
   modifier checkExchange(){
      require(exchangeAddress != address(0), "Exchange address not obtained!");
      _;
   }

   // 正常な非クリエイターであるか確認
   modifier  checkNormalUser(Users functionFrag){
      require(!isBANUser, "You are prohibited from using the user function.");
      require((userFunctionFrags & uint16(1 << uint16(functionFrag))) != 0);
      _;
   }
   
   // 正常なクリエイターであるか確認
   modifier  checkNormalCreator(Creators functionFrag){
      require(!isBANCreator, "You are prohibited from using the creator function.");
      require((creatorFunctionFrags & uint16(1 << uint16(functionFrag))) != 0);
      _;
   }
}