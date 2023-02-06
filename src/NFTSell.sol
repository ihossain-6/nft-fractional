//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NotEnoughMoney();
error TooMuchAmount();
error SoldOut();
error NoETH();

contract NFTSell is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct Product {
        uint256 _productId;
        string _productName;
        uint256[] _idOfTokens;
        uint256 _amount;
        uint256 _price;
        uint256 _left;
    }

    address[] private s_buyers;
    IERC721 private nft;
    Counters.Counter private s_tokenId;
    mapping(uint256 => Product) private s_productsById;
    uint256 private s_nextProductId;

    event ProductListed(
        uint256 indexed _productId,
        string indexed _productName,
        uint256 indexed _price,
        uint256[] _tokenIds
    );
    event ProductBought(uint256 indexed _productId, uint256[] _tokenIds);

    constructor(IERC721 _nft) {
        s_buyers.push(address(0));
        nft = _nft;
        s_nextProductId = 0;
    }

    function list(
        string memory _productName,
        uint256[] calldata _tokenIds,
        uint256 _price
    ) external onlyOwner {
        Product storage product = s_productsById[s_nextProductId];

        uint256 _tokenLength = _tokenIds.length;

        for (uint256 i; i < _tokenLength; ++i) {
            require(nft.ownerOf(_tokenIds[i]) == msg.sender);

            nft.transferFrom(msg.sender, address(this), _tokenIds[i]);

            product._idOfTokens.push(_tokenIds[i]);
        }
        emit ProductListed(s_nextProductId, _productName, _price, _tokenIds);
        _listProduct(_productName, _tokenIds, _price);
    }

    function _listProduct(
        string memory _productName,
        uint256[] calldata _tokenIds,
        uint256 _price
    ) internal onlyOwner {
        s_productsById[s_nextProductId] = Product(
            s_nextProductId,
            _productName,
            _tokenIds,
            _tokenIds.length,
            _price,
            _tokenIds.length
        );
        s_nextProductId++;
    }

    function buy(uint256 _productId, uint256[] calldata _tokenIds) external payable nonReentrant {
        Product memory product = s_productsById[_productId];
        if (msg.value < product._price * _tokenIds.length) {
            revert NotEnoughMoney();
        }
        if (_tokenIds.length > product._left) {
            revert TooMuchAmount();
        }
        if (product._left == 0) {
            revert SoldOut();
        }
        _buy(_productId, _tokenIds);
        if (!_checkBuyer()) {
            s_buyers.push(msg.sender);
        }
        _updateLeft(_productId, _tokenIds);
        emit ProductBought(_productId, _tokenIds);
    }

    function _buy(uint256 _productId, uint256[] calldata _tokenIds) internal {
        Product storage product = s_productsById[_productId];

        uint256 tokenIdLength = _tokenIds.length;
        for (uint256 i; i < tokenIdLength; ++i) {
            uint256 tokenLen = product._idOfTokens.length;
            for (uint256 j; j < tokenLen; ++j) {
                if (product._idOfTokens[j] == _tokenIds[i]) {
                    product._idOfTokens[product._idOfTokens.length - 1] = product._idOfTokens[j];
                    product._idOfTokens.pop();
                    break;
                }
            }

            nft.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
    }

    function _updateLeft(uint256 _productId, uint256[] calldata _tokenIds) internal view {
        Product storage product = s_productsById[_productId];
        product._left.sub(_tokenIds.length);
    }

    function _checkBuyer() internal view returns (bool) {
        for (uint256 i; i < s_buyers.length; i++) {
            if (s_buyers[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function withdraw() external payable onlyOwner {
        if (address(this).balance == 0) {
            revert NoETH();
        }
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function seeBuyers(uint256 _index) external view returns (address) {
        return s_buyers[_index];
    }

    function seeProductById(uint256 _id) external view returns (Product memory) {
        return s_productsById[_id];
    }

    function seeNextProductId() external view returns (uint256) {
        return s_nextProductId;
    }
}
