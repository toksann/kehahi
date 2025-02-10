// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";
import "interfaces/AccessKey/ILaunchKey.sol";
import "contracts/ExData/ProcessCounter.sol";
import "interfaces/AccessKey/IAccessKey.sol";

// アクセスキーの定義
contract AccessKey is IAccessKey, ERC20, ERC20Burnable, Ownable {
    uint256 public price;  // 価格を記録
    bool public priceFluctuations; // 価格変動フラグ

    uint256[] private holders;   // アクセスキーの保有者IDリスト
    mapping (uint256 => address) private id2Holders;   // 保有者IDと保有者アドレス
    mapping (address => uint256) private holders2Id;   // 保有者アドレスと保有者ID

    address public launchKey;  // 予約情報確認用
    address public tradeCounter;  // ユーザー間取引の集計

    constructor(string memory name, string memory symbol, bool _priceFluctuations)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        price = 0;
        setPriceFluctuate(_priceFluctuations);
        tradeCounter = address(new ProcessCounter());
    }

    // アクセスキーの発行
    function mint(address to, uint256 editionId) public {
        require(AccessKey(address(this)).balanceOf(to) == 0, "You are already an holder."); // 既に保有している場合は受け取れない
        require(ILaunchKey(launchKey).queryLaunch(address(this), editionId), "You have not booked.");    // 予約済か確認

        // 発行する
        _mint(to, 1);
        addHolder();    // 保有者リストに追加
    }

    // アクセスキーの焼却
    function burn(address from) public {
        require(AccessKey(address(this)).balanceOf(from) == 1, "You do not have an access key."); // 保有してない場合は焼却できない

        // 焼却する
        _burn(from, 1);

        // ポイントを配布する
        // 配布処理をExPoint内に作る予定(数量もそちらで設定(数量の計算自体はManageExが担当する))
    }

    // 価格を設定する
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // 価格変動を設定する
    function setPriceFluctuate(bool _priceFluctuations) private onlyOwner {
        priceFluctuations = _priceFluctuations;
    }

    // 変動相場をONにする
    function fluctuateEnable() external {
        setPriceFluctuate(true);
    }

    // 変動相場をOFFにする（固定相場へ移行するので、決まった価格を設定）
    function fluctuateDisable(uint256 newPrice) external {
        setPriceFluctuate(false);
        setPrice(newPrice);
    }

    // 保有者を追加する
    function addHolder() private {
        id2Holders[holders.length] = msg.sender;
        holders2Id[msg.sender] = holders.length;
        holders.push(holders.length);
    }

    // 保有者リストを相手のアドレスと入れ替える
    function swapHolder(address from, address to) public {
        id2Holders[holders2Id[from]] = to;  // fromと紐づいているIDを使って、IDとtoを紐づける
        holders2Id[to] = holders2Id[from];  // toに、fromと紐づいているIDを紐づける
        delete holders2Id[from];    // fromと紐づいているIDが不要になるので削除する
    }

    // アクセスキーの分割
    function splitKey(uint256 splitRate) external onlyOwner {
        for (uint i = 0; i < holders.length; i++) 
        {
            address _holder = id2Holders[holders[i]];
            uint256 currentAmount = AccessKey(address(this)).balanceOf(_holder);
            
            // balanceOfで確認した保有分*分割数の不足分をmintする
            _mint(_holder, currentAmount * splitRate - currentAmount);
        }
    }

    // ローンチ情報のアドレスを与える
    function setLaunchInfo(address _launchKey) external onlyOwner{
        launchKey = _launchKey;
    }

    // priceのgetter
    function getPrice() external view returns(uint256) {
        return price;
    }

    // priceFluctuationsのgetter
    function getPriceFluctuations() external view returns(bool) {
        return priceFluctuations;
    }

    // launchKeyのgetter
    function getLaunchKey() external view returns(address) {
        return launchKey;
    }

    // tradeCounterのgetter
    function getTradeCounter() external view returns(address) {
        return tradeCounter;
    }
}