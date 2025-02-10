// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IPerpetualKey Interface
 * @dev This interface defines only the functionality required to implement PerpetualKey from the ERC1155.
 */
interface IPerpetualKey is IERC1155 {
    /**
     * @dev Mint a new token of the given id and amount.
     * @param account The address to mint the token to.
     * @param id The id of the token to mint.
     * @param data Additional data with no specified format.
     */
    function mint(
        address account,
        uint256 id,
        bytes memory data
    ) external;
}