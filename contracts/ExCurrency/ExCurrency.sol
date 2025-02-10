// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";

// 取引所テスト用通貨の発行及び焼却、受け渡しにかかる処理(ownerは取引所)
contract ExCurrency is ERC20, ERC20Burnable, Ownable {
    string public constant EX_CURRENCY_NAME = "ExchangeCurrency";
    string public constant EX_CURRENCY_SYMBOL = "EXC";

    constructor(uint256 initialSupply)
        ERC20(EX_CURRENCY_NAME, EX_CURRENCY_SYMBOL)
        Ownable(msg.sender)
    {
        if(initialSupply > 0){
            _mint(msg.sender, initialSupply * 10 ** decimals());
        }
    }

    // 取引所テスト用通貨の発行
    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }

    // 取引所テスト用通貨の焼却
    function burn(address from, uint256 value) public onlyOwner {
        // 焼却する
        _burn(from, value);
    }

    // 権限保有者を返す
    function getOwner() public view returns (address){
        return  owner();
    }
}