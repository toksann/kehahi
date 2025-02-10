// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.2/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@5.0.2/access/Ownable.sol";

// 取引所ポイントトークンの発行及び焼却、受け渡しにかかる処理(ownerは取引所)
contract ExPoint is ERC20, ERC20Burnable, Ownable {
    string public constant EX_POINT_NAME = "ExchangePoint";
    string public constant EX_POINT_SYMBOL = "EXP";

    constructor(uint256 initialSupply)
        ERC20(EX_POINT_NAME, EX_POINT_SYMBOL)
        Ownable(msg.sender)
    {
        if(initialSupply > 0){
            _mint(msg.sender, initialSupply * 10 ** decimals());
        }
    }

    // 取引所ポイントトークンの発行
    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }

    // 取引所ポイントトークンの焼却
    function burn(address from, uint256 value) public onlyOwner {
        // 焼却する
        _burn(from, value);
    }

    // 権限保有者を返す
    function getOwner() public view returns (address){
        return  owner();
    }
}