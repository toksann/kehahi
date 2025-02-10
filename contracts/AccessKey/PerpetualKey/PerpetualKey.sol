// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "contracts/AccessKey/PerpetualKey/IPerpetualKey.sol";

contract PerpetualKey is ERC1155, IPerpetualKey {
    constructor(string memory uri) ERC1155(uri) {}

    function mint(
        address account,
        uint256 id,
        bytes memory data
    ) public virtual override {
        _mint(account, id, 1, data);
    }
}