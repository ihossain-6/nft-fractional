//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CollectionNFT is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    uint256 constant maxSupply = 10000;

    Counters.Counter private _tokenId;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address _owner, uint256 _amount, string memory _tokenURI) external {
        for (uint256 i; i < _amount; i++) {
            _tokenId.increment();
            uint256 tokenId = _tokenId.current();
            _safeMint(_owner, tokenId);
            _setTokenURI(tokenId, _tokenURI);
        }
    }

    function tokensOwned(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokens = balanceOf(_owner);
        uint256[] memory ownerTokenIds = new uint256[](ownerTokens);
        for (uint256 i; i < ownerTokens; i++) {
            ownerTokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return ownerTokenIds;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        return super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
