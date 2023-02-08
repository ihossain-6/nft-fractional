// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "../src/NFTSell.sol";
import "./utils/Cheats.sol";

contract TestNFTSell is Test {
    NFT public _nft;
    NFTSell public _nftSell;
    uint256 public _amount = 10;
    string public _tokenURI =
        "https://ipfs.io/ipfs/QmPwp5kCCtCt5HVoeXx9WSCvsRyRTv8U2oDcyNX4eq2A6G?filename=Metadata2.json";

    function setUp() public {
        _nft = new NFT("NFT Sell Token", "NST");
        _nftSell = new NFTSell(_nft);
    }

    function test_ProductIdInitialization() public {
        assertEq(_nftSell.seeNextProductId(), 0);
    }

    function test_BuyersArrayInitialization() public {
        assertEq(_nftSell.seeBuyers(0), address(0));
    }
}

contract TestList is Test {
    NFT public _nft;
    NFTSell public _nftSell;
    uint256 public _price = 1e17;
    string public _productName = "Course";
    uint256[] public _tokenIds = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint256 public _productId = 0;
    uint256 public _amount = 10;
    string public _tokenURI =
        "https://ipfs.io/ipfs/QmPwp5kCCtCt5HVoeXx9WSCvsRyRTv8U2oDcyNX4eq2A6G?filename=Metadata2.json";

    event ProductListed(
        uint256 indexed _productId,
        string indexed _productName,
        uint256 indexed _price,
        uint256[] _tokenIds
    );

    function setUp() public {
        _nft = new NFT("NFT Sell Token", "NST");
        _nftSell = new NFTSell(_nft);
        _nft.mint(_nftSell.owner(), _amount, _tokenURI);
        _nft.setApprovalForAll(address(_nftSell), true);
    }

    function test_RevertIfNotOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        _nftSell.list(_productName, _tokenIds, _price);
    }

    function test_TransfersNFTCorrectly() public {
        vm.prank(_nftSell.owner());
        _nftSell.list(_productName, _tokenIds, _price);
        assertEq(_nft.ownerOf(1), address(_nftSell));
    }

    function test_UpdatesProductTokenIdArray() public {
        vm.prank(_nftSell.owner());
        _nftSell.list(_productName, _tokenIds, _price);
        uint256 _listedTokenIdsLength = _nftSell.seeProductById(0)._idOfTokens.length;
        assertEq(_listedTokenIdsLength, 9);
    }

    function test_EmitEvent() public {
        vm.expectEmit(true, true, true, true);
        emit ProductListed(_productId, _productName, _price, _tokenIds);
        vm.prank(_nftSell.owner());
        _nftSell.list(_productName, _tokenIds, _price);
    }

    function test_UpdateProductId() public {
        vm.prank(_nftSell.owner());
        _nftSell.list(_productName, _tokenIds, _price);
        assertEq(_nftSell.seeNextProductId(), 1);
    }
}

contract TestBuy is Test {
    NFT public _nft;
    NFTSell public _nftSell;
    uint256 public _price = 1e17;
    string public _productName = "Course";
    uint256[] public _tokenIds = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint256 public _productId = 0;
    uint256[] public _buyingIds = [1, 3, 5];
    uint256 public _amount = 10;
    string public _tokenURI =
        "https://ipfs.io/ipfs/QmPwp5kCCtCt5HVoeXx9WSCvsRyRTv8U2oDcyNX4eq2A6G?filename=Metadata2.json";
    uint256[] public _buyingIdExceeding = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    uint256[] public _soldOutIds = [1];

    event ProductBought(uint256 indexed _productId, uint256[] _tokenIds);

    function setUp() public {
        _nft = new NFT("NFT Sell Token", "NST");
        _nftSell = new NFTSell(_nft);
        _nft.mint(_nftSell.owner(), _amount, _tokenURI);
        _nft.setApprovalForAll(address(_nftSell), true);
        vm.prank(_nftSell.owner());
        _nftSell.list(_productName, _tokenIds, _price);
    }

    function test_RevertIfNotEnoughMoney() public {
        vm.expectRevert();
        _nftSell.buy{value: 1e16}(_productId, _buyingIds);
    }

    function test_RevertIfTooMuchAmount() public {
        vm.expectRevert(bytes4(keccak256("TooMuchAmount()")));
        _nftSell.buy{value: 1e18}(_productId, _buyingIdExceeding);
    }

    function test_ReducesProductTokenIdLength() public {
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
        uint256 _len = _nftSell.seeProductById(_productId)._idOfTokens.length;
        assertEq(_len, 6);
    }

    function test_ItPushesBuyer() public {
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
        assertEq(_nftSell.seeBuyers(1), address(this));
    }

    function test_TransfersNFTToBuyer() public {
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
        assertEq(_nft.ownerOf(1), address(this));
    }

    function test_UpdatesLeft() public {
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
        uint256 _left = _nftSell.seeProductById(0)._left; 
        assertEq(_left, 6);
    }

    function test_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit ProductBought(_productId, _buyingIds);
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
    }

    function test_ContractTakesEther() public {
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
        assertEq(address(_nftSell).balance, 3e17);
    }

    function test_RevertsWhenTokenSold() public {
        _nftSell.buy{value: 9e17}(_productId, _tokenIds);
        vm.expectRevert();
        _nftSell.buy{value: 1e17}(_productId, _soldOutIds);
    }
}

contract TestWithdraw is Test {
    NFT public _nft;
    NFTSell public _nftSell;
    uint256 public _price = 1e17;
    string public _productName = "Course";
    uint256 public _productId = 0;
    uint256[] public _tokenIds = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    uint256[] public _buyingIds = [1, 3, 5];
    uint256 public _amount = 10;
    string public _tokenURI =
        "https://ipfs.io/ipfs/QmPwp5kCCtCt5HVoeXx9WSCvsRyRTv8U2oDcyNX4eq2A6G?filename=Metadata2.json";

    function setUp() public {
        _nft = new NFT("NFT Sell Token", "NST");
        _nftSell = new NFTSell(_nft);
        _nft.mint(_nftSell.owner(), _amount, _tokenURI);
        _nft.setApprovalForAll(address(_nftSell), true);
        vm.prank(_nftSell.owner());
        _nftSell.list(_productName, _tokenIds, _price);
    }

    function test_Withdraw() public {
        _nftSell.buy{value: 3e17}(_productId, _buyingIds);
        vm.prank(_nftSell.owner());
        _nftSell.withdraw();
        assertEq(address(_nftSell).balance, 0);
    }

    function test_RevertIfZero() public {
        vm.startPrank(_nftSell.owner());
        vm.expectRevert(bytes4(keccak256("NoETH()")));
        _nftSell.withdraw();
        vm.stopPrank();
    }

    receive() external payable {}
    
    fallback() external payable {}
}