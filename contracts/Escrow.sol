//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress; // gayrimenkuladdresi gibi
    address public inspector; //müfettiş adresi
    address payable public seller; // satıcının adresi payable ether gön. almak için
    address public lender; // borç veren kiracı

    

    mapping(uint256 => bool) public isListed; //nftlerin listelenip listelenmediğini kont ediyor
    mapping(uint256 => uint256) public purchasePrice; // satın alma fiyatı
    mapping(uint256 => uint256) public escrowAmount; //emanet tutarı
    mapping(uint256 => address) public buyer; // alıcı adresi
    mapping(uint256 => bool) public inspectionPassed; //müfetişten geçip geçmemesi
    mapping(uint256 => mapping(address => bool)) public approval; // onay almak için

    constructor(
        address _nftaddress,
        address _inspector,
        address payable  _seller,
        address _lender
    ) {
        nftAddress = _nftaddress;
        inspector = _inspector;
        seller = _seller;
        lender = _lender;
    }

    // mülkiyeti nft olarak bu kont. adresine gönderiyor
    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable  {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

        isListed[_nftID] = true; //nftid ile listelenmeyi dogruluyor
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

    // yalnıza alıcılar için geçerli
    function depositEarnest(uint256 _nftID) public payable  {
        require(msg.value >= escrowAmount[_nftID]); // emanet bedelinden fazla veya eşit deilse hata verir
    }

    // evin müfettişten geçip geçmemesi
    function updateInspectionStatus(uint256 _nftID, bool _passsed)
        public
       
    {
        inspectionPassed[_nftID] = _passsed;
    }

    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    // satış için
    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID]);
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false;

        (bool success, ) = payable(seller).call{value: address(this).balance}(
            " "
        );
        require(success);

        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

    

    receive() external payable {
        // kont. dışından ödeme yapabilir
    }

    // bu kont. hesabında bulunan parayı kontrol ediyor
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
