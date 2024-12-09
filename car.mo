// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract CarNFTMarketplace is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _carModelIds;

    // Araç modeli yapısı
    struct CarModel {
        string brand;
        string model;
        uint256 year;
        uint256 mileage;
        uint256 basePrice;
        bool isVerified;
    }

    // Araç NFT yapısı
    struct CarNFT {
        uint256 carModelId;
        uint256 originalPrice;
        address[] previousOwners;
        uint256 lastSoldPrice;
    }

    // Fiyat ve sahiplik geçmişi
    mapping(uint256 => CarModel) public carModels;
    mapping(uint256 => CarNFT) public carNFTs;
    mapping(address => uint256[]) public userCarCollection;

    // Etkinlik logları
    event CarModelRegistered(uint256 indexed carModelId, string brand, string model);
    event CarNFTMinted(uint256 indexed tokenId, address minter, uint256 price);
    event CarSold(uint256 indexed tokenId, address from, address to, uint256 price);

    constructor() ERC721("CarChain NFT", "CARNFT") {}

    // Yeni araç modeli ekleme fonksiyonu
    function registerCarModel(
        string memory _brand, 
        string memory _model, 
        uint256 _year, 
        uint256 _mileage, 
        uint256 _basePrice
    ) public onlyOwner returns (uint256) {
        _carModelIds.increment();
        uint256 newCarModelId = _carModelIds.current();

        carModels[newCarModelId] = CarModel({
            brand: _brand,
            model: _model,
            year: _year,
            mileage: _mileage,
            basePrice: _basePrice,
            isVerified: true
        });

        emit CarModelRegistered(newCarModelId, _brand, _model);
        return newCarModelId;
    }

    // Araç NFT'si mint etme
    function mintCarNFT(uint256 _carModelId) public payable {
        require(carModels[_carModelId].isVerified, "Car model not verified");
        require(msg.value >= carModels[_carModelId].basePrice, "Insufficient payment");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);

        carNFTs[newTokenId] = CarNFT({
            carModelId: _carModelId,
            originalPrice: msg.value,
            previousOwners: new address[](0),
            lastSoldPrice: msg.value
        });

        userCarCollection[msg.sender].push(newTokenId);

        emit CarNFTMinted(newTokenId, msg.sender, msg.value);
    }

    // NFT transferi
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);

        // Sahiplik geçmişini güncelle
        carNFTs[tokenId].previousOwners.push(from);
        userCarCollection[to].push(tokenId);
    }

    // Araç detaylarını alma
    function getCarDetails(uint256 _tokenId) public view returns (CarModel memory, CarNFT memory) {
        return (carModels[carNFTs[_tokenId].carModelId], carNFTs[_tokenId]);
    }

    // Kullanıcının araç koleksiyonunu alma
    function getUserCars(address _user) public view returns (uint256[] memory) {
        return userCarCollection[_user];
    }

    // Platform için para çekme
    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
