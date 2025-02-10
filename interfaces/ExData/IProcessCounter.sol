// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProcessCounter {
    // イベント
    event ProcessCountRecorded(uint256 blockNumber, uint256 count);

    // 定数
    function BLOCKS_PER_RECORD() external pure returns (uint256);
    function BLOCKS_PER_DAY() external pure returns (uint256);

    // 処理回数の記録
    function recordProcessCount() external;

    // 合計値の取得
    function getAccumulatedCount() external view returns (uint256);
}
