// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "interfaces/AccessKey/IAccessKey.sol";
import "interfaces/ExData/IProcessCounter.sol";

// 注意事項
// * アクセスキーはERC20を継承している。
//  IAccessKeyでアクセスキーの独自機能を呼びだせるが、それ以外のERC20トークンとしての機能はIERC20を使って呼びだす必要がある。

// アクセスキートークンの取引処理(ownerは取引所?)
contract TradeKey {
    // 代金用ERC20トークンアドレス(ゆくゆくなくす)
    address public immutable paymentToken;

    struct Transaction {
        address buyer;  // 買い手
        address seller; // 売り手
        address accessKey;  // 取引対象
        uint paymentAmount; // 代金
        uint accessKeyAmount;   // 取引数量
    }

    mapping(bytes32 => Transaction) public transactions;

    event TransactionInitiated(bytes32 indexed _txId, address indexed _buyer, address indexed _seller, address _accessKey);
    event PaymentTransferred(bytes32 indexed _txId, address indexed _recipient, uint _amount, uint tradeFee);
    event AccessKeyTransferred(bytes32 indexed _txId, address indexed _recipient, address _accessKey, uint _amount);
    event TransactionCompleted(bytes32 indexed _txId);

    constructor(address _paymentToken){
        paymentToken = _paymentToken;
    }

    // 取引処理(メインの処理であり、以下の各関数を含む)
    function trade(bytes32 _txId, address _buyer, address _seller, address _accessKey) external { 
        // _txIdの重複チェック
        if(checkTx(_txId)) revert();
        
        // 価格決定処理
        uint256 _paymentAmount = 0;

        // 取引対象が変動相場を許可しているか確認する
        if(IAccessKey(_accessKey).priceFluctuations()) {   
            // _paymentAmount = pricing();  // 価格を導出(引数は必要に応じて対応)
        } else {
            _paymentAmount = IAccessKey(_accessKey).price(); // 固定相場なら導出ではなく、固定値で取引する
        }

        // 取引対象と代金の第三者受け取り
        initiateTransaction(_txId, _buyer, _seller, _paymentAmount, _accessKey);

        // 代金トークンを売り手に転送
        transferPayment(_txId, _seller);

        // アクセスキートークンを買い手に転送
        transferAccessKey(_txId, _buyer);

        // アクセスキーデータの更新
        updateAccessKey(_accessKey, _paymentAmount);

        // 保有者を売り手から買い手に入れ替える
        IAccessKey(_accessKey).swapHolder(_seller, _buyer);

        // 取引完了処理
        completeTransaction(_txId);
    }
    
    // 取引開始 (代金トークンとアクセスキートークンの預かり)
    function initiateTransaction(bytes32 _txId, address _buyer, address _seller, uint _paymentAmount, address _accessKey) internal {
        // 売り手がアクセスキートークンを保有していることを確認
        require(IERC20(_accessKey).balanceOf(_seller) >= 1, "The seller does not have the item.");

        // 買い手がアクセスキートークンを保有していないことを確認
        require(IERC20(_accessKey).balanceOf(_buyer) == 0, "The buyer already has the item.");

        // 代金トークンの受け取り
        require(IERC20(paymentToken).transferFrom(_buyer, address(this), _paymentAmount), "Payment token transfer failed");
        
        // アクセスキートークンの受け取り
        require(IERC20(_accessKey).transferFrom(_seller, address(this), 1), "AccessKey token transfer failed");

        transactions[_txId] = Transaction({
           buyer: _buyer,
           seller: address(0),
           accessKey: _accessKey,
           paymentAmount: _paymentAmount,
           accessKeyAmount: 1
        });

        emit TransactionInitiated(_txId, _buyer, _seller, _accessKey);
    }

    // 代金トークンの転送
    function transferPayment(bytes32 _txId, address _seller) internal {
        //Transaction storage txData = transactions[_txId];];     //省ガス化のためすべて直接呼ぶ方法に変更
        
        // アクセス制御とデータ検証
        require(transactions[_txId].buyer == _seller, "Not a seller");
        require(transactions[_txId].seller == address(0), "Seller already set");
        require(IERC20(paymentToken).balanceOf(address(this)) >= transactions[_txId].paymentAmount, "Insufficient payment tokens");

        // 売り手アドレスを設定
        transactions[_txId].seller = _seller;

        // 代金から手数料を徴収し、送金額を手数料だけ減額する
        uint tradeFee /* =  calcurateFee的なのを呼びだして手数料を設定*/;
        uint fixPaymentAmount = transactions[_txId].paymentAmount - tradeFee;

        // 代金トークンの送金
        require(IERC20(paymentToken).transfer(transactions[_txId].seller, fixPaymentAmount), "Payment transfer failed");

        // 手数料を取引所へ送金
        /* 取引所のアドレスを受け取っておいて、ここでtransferする*/

        // 売り手にExPointを付与する
        /* ExPointのアドレスを受け取っておいて、ここでmintする*/

        // イベントの発行
        emit PaymentTransferred(_txId, transactions[_txId].seller, transactions[_txId].paymentAmount, tradeFee);
    }

    // アクセスキートークンの転送
    function transferAccessKey(bytes32 _txId, address _buyer) internal {
        //Transaction storage txData = transactions[_txId];     //省ガス化のためすべて直接呼ぶ方法に変更

        // アクセス制御とデータ検証
        require(transactions[_txId].buyer == _buyer, "Not a buyer");
        require(transactions[_txId].seller != address(0), "Seller not set");  
        require(IERC20(transactions[_txId].accessKey).balanceOf(address(this)) >= transactions[_txId].accessKeyAmount, "Insufficient accessKey tokens");

        // アクセスキートークンの送金
        require(IERC20(transactions[_txId].accessKey).transfer(transactions[_txId].buyer, transactions[_txId].accessKeyAmount), "AccessKey transfer failed");

        // イベントの発行 
        emit AccessKeyTransferred(_txId, transactions[_txId].buyer, transactions[_txId].accessKey, transactions[_txId].accessKeyAmount);
    }

    // 取引完了
    function completeTransaction(bytes32 _txId) internal {
        //Transaction storage txData = transactions[_txId];];     //省ガス化のためすべて直接呼ぶ方法に変更

        // 両方のトークン送金が完了したことを確認
        require(transactions[_txId].buyer != address(0), "Buyer not set");
        require(transactions[_txId].seller != address(0), "Seller not set");
        require(IERC20(paymentToken).balanceOf(address(this)) == 0, "Payment tokens not transferred");
        require(IERC20(transactions[_txId].accessKey).balanceOf(address(this)) == 0, "AccessKey tokens not transferred");

        // 取引完了を記録
        emit TransactionCompleted(_txId);

        // データをリセット
        delete transactions[_txId];
    }

    // トランザクションの重複チェック(重複していたらtrue)
    function checkTx(bytes32 _txId) internal view returns (bool) {
        if(transactions[_txId].buyer != address(0) &&
        transactions[_txId].seller != address(0) &&
        transactions[_txId].accessKey != address(0) &&
        transactions[_txId].paymentAmount > 0 &&
        transactions[_txId].accessKeyAmount > 0) {
            return true;
        }
        return false;
    }

    // アクセスキーデータの更新
    function updateAccessKey(address _accessKey, uint256 _paymentAmount) private {
        if(IAccessKey(_accessKey).priceFluctuations()) IAccessKey(_accessKey).setPrice(_paymentAmount);   // 取引価格を反映する（変動相場のときのみ）

        address tradeCounter = IAccessKey(_accessKey).tradeCounter();
        IProcessCounter(tradeCounter).recordProcessCount();  // トレード回数を更新する
    }
}