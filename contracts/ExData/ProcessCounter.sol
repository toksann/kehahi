// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// このコントラクトでは取引所の財政処理に必要な"1日ごとの処理回数"を集計し、保管する機能を実装する。
// 集計対象
// * AccessKeyごとのトレード回数

// 利用方法
// * このコントラクトを集計対象の処理を持つコントラクトにimportする。
// * このコントラクトのインスタンスを生成し、アドレスを保持する。
// * 集計対象の処理中でrecordProcessCount()を呼び出し、実行毎に回数を加算する。
// * 集計データを利用するコントラクトでは、集計対象の処理をもつコントラクトのインスタンスにアクセスし、getAccumulatedCount()から集計データを参照する。

import "interfaces/ExData/IProcessCounter.sol";
import "contracts/ExData/ExAssetIO.sol";    // アクセスキー経由で、Exchangeで生成したExAssetIOのアドレスをここに渡す（ここにもコンストラクタ書かないとね！）

contract ProcessCounter is IProcessCounter {
    // 処理回数の記録用の構造体
    struct ProcessCount {
        uint256 blockNumber;
        uint256 count;
    }

    // 処理回数の記録用の配列
    ProcessCount[] private processCountArray;

    // 記録単位のブロック数
    uint256 constant public BLOCKS_PER_RECORD = 240; // 1時間分のブロック数
    uint256 constant public BLOCKS_PER_DAY = 24 * 60 * 60 / 15;    // 1日に生成されるブロックの目安

    // 合計値の管理用変数
    uint256 private accumulatedCount;

    // 処理回数の記録
    function recordProcessCount() external {
        uint256 currentBlockNumber = block.number;

        // 記録が初回ではない場合
        if (processCountArray.length > 0) {
            // 最後の記録と BLOCKS_PER_RECORD 以上離れている場合
            if (currentBlockNumber - processCountArray[processCountArray.length - 1].blockNumber >= BLOCKS_PER_RECORD) {
                // 新しい記録を追加
                processCountArray.push(ProcessCount(currentBlockNumber, 1));
                accumulatedCount++;
            } else {
                // 最後の記録の回数を加算
                processCountArray[processCountArray.length - 1].count++;
                accumulatedCount++;
            }
        } else {
            // 最初の記録
            processCountArray.push(ProcessCount(currentBlockNumber, 1));
            accumulatedCount++;
        }

        // 記録単位のブロック数を超えた場合、先頭の記録を削除
        if (processCountArray.length > BLOCKS_PER_DAY / BLOCKS_PER_RECORD) {
            accumulatedCount -= processCountArray[0].count;
            for (uint256 i = 1; i < processCountArray.length; i++) {
                processCountArray[i - 1] = processCountArray[i];    // 配列要素を一つ前にシフトする(先頭の記録を上書きする)
            }
            processCountArray.pop();    // 最後尾の要素を削除する
        }

        emit ProcessCountRecorded(currentBlockNumber, accumulatedCount);
    }

    // 外部コントラクトで利用する加算値の算出
    function getAccumulatedCount() external view returns (uint256) {
        return accumulatedCount;
    }
}