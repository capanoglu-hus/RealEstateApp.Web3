//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    // nft yi kulanmaya yarıyor
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

    modifier onlyBuyer(uint256 _nftID) {
        //buyer nftidsi gönderen ile aynı değilse hata verir
        require(msg.sender == buyer[_nftID], "Only buyer can call this method");
        _;
    }

    modifier onlySeller() {
        //seller adresi  gönderen ile aynı değilse hata verir
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector() {
         //inspector  adresi  gönderen ile aynı değilse hata verir
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    mapping(uint256 => bool) public isListed; //nftlerin listelenip listelenmediğini kont ediyor
    mapping(uint256 => uint256) public purchasePrice; // satın alma fiyatı
    mapping(uint256 => uint256) public escrowAmount; //emanet tutarı
    mapping(uint256 => address) public buyer; // alıcı adresi
    mapping(uint256 => bool) public inspectionPassed; //müfetişten geçip geçmemesi
    mapping(uint256 => mapping(address => bool)) public approval; // onay almak için

    constructor( //yapılandırıcı
        address _nftAddress,
        address payable _seller,
        address _inspector,
        address _lender
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

    // mülkiyeti nft olarak bu kont. adresine gönderiyor

    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // transferi nft olarak göndermesi
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

        isListed[_nftID] = true; //nftid ile listelenmeyi dogruluyor
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

 
    // yalnızca alıcılar için geçerli
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID]); // emanet bedelinden fazla veya eşit deilse hata verir
    }

    // evin müfettişten geçip geçmemesi
    function updateInspectionStatus(uint256 _nftID, bool _passsed) public onlyInspector{
        inspectionPassed[_nftID] = _passsed; 
    }

    // Satışı onaylama 
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    // satış için
    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID]); //mufettişten geçmesi lazım 
        require(approval[_nftID][buyer[_nftID]]); 
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false; // listelemede olmuyacak 

        //bu kont. adresi degerinin satıcı tarafından belirleme 
        (bool success, ) = payable(seller).call{value: address(this).balance}(
            " "
        );
        require(success);
        // nft transfer için parametre
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

   // satış iptali 
    function cancelSale(uint256 _nftID) public {
        if (inspectionPassed[_nftID] == false) {
            payable(buyer[_nftID]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }

    receive() external payable {
        // kont. dışından ödeme yapabilir
    }

    // bu kont. hesabında bulunan parayı kontrol ediyor
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
