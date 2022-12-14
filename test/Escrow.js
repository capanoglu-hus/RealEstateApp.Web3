
const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), "ether");

}

describe('Escrow', () => {

    let buyer, seller, inspector, lender  //alıcı ve staıcı hesaplarını oluşturmak için 
    let realEstate, escrow //kont. adları 

    beforeEach(async () => {
        [buyer, seller, inspector, lender] = await ethers.getSigners() // ether hesaplarını olacak imzalayanlar  

        //deploy realestate 
        const RealEstate = await ethers.getContractFactory('RealEstate')
        realEstate = await RealEstate.deploy()

        // nft basmak için 
        let transaction = await realEstate.connect(seller).mint("https://ipfs.io/ipfs/QmTudSYeM7mz3PkYEWXWqPjomRPHogcMFSq7XAvsvsgAPS")
        await transaction.wait()

        //deploy escrow -- özellikleriyle beraber 
        const Escrow = await ethers.getContractFactory('Escrow')
        escrow = await Escrow.deploy(
            realEstate.address,
            seller.address,
            inspector.address,
            lender.address
        )

        //mülkiyet onayı
        transaction = await realEstate.connect(seller).approve(escrow.address, 1) //satıcının adresini onaylaması 
        await transaction.wait() // transferi bekleme 

        //özellikleri listeliyecez 
        transaction = await escrow.connect(seller).list(1, buyer.address, tokens(10), tokens(5))
        await transaction.wait()

    })


    describe('Deployment', () => {
        //kont. özelliklerinin adresinin eşit olması 
        it('Returns NFT address', async () => {
            const result = await escrow.nftAddress()
            expect(result).to.be.equal(realEstate.address)
        })

        it('Returns seller', async () => {
            const result = await escrow.seller()
            expect(result).to.be.equal(seller.address)
        })

        it('Returns inspector', async () => {
            const result = await escrow.inspector()
            expect(result).to.be.equal(inspector.address)
        })

        it('Returns lender', async () => {
            const result = await escrow.lender()
            expect(result).to.be.equal(lender.address)

        })


    })

    describe('listing', () => {
        //nftlerin listelenmesi

        it('updates as listed', async () => {
            const result = await escrow.isListed(1)
            expect(result).to.be.equal(true) // listeleme güncellemesini test ediyor
        })

        //alıcı için 
        it('returns buyer', async () => {
            const result = await escrow.buyer(1)
            expect(result).to.be.equal(buyer.address)
        })

        //satın alma fiyatı 
        it('Returns purchase price', async () => {
            const result = await escrow.purchasePrice(1)
            expect(result).to.be.equal(tokens(10))
        })

        //satın alma fiyatı 
        it('returns escrow amount', async () => {
            const result = await escrow.escrowAmount(1)
            expect(result).to.be.equal(tokens(5))
        })

        //gönderilen adreslemülkiyet için emanette bulunan adresin aynı olup olmadıgı kont ediyor
        it('updates ownership', async () => {
            expect(await realEstate.ownerOf(1)).to.be.equal(escrow.address)
        })
    })

    describe('Deposits', () => {
        // cüzdandaki degerin emanet degerinden büyük olmasını test ediyor 
        beforeEach(async () => {
            const transaction = await escrow.connect(buyer).depositEarnest(1, { value: tokens(5) })
            await transaction.wait()
        })

        it('updates contract balance', async () => {

            //emanette bulunan parayla eşit mi diye bakıyor 
            const result = await escrow.getBalance()
            expect(result).to.be.equal(tokens(5))
        })
    })

    describe('Inspection', () => {
        // müfettiş durumunu gösterme 
        beforeEach(async () => {
            const transaction = await escrow.connect(inspector).updateInspectionStatus(1, true)
            await transaction.wait()
        })

        it('updates inspector', async () => {
            const result = await escrow.inspectionPassed(1)
            expect(result).to.be.equal(true)
        })
    })

    describe('Approval', () => {
        // karşılıklı onaylama durumu 
        beforeEach(async () => {
            let transaction = await escrow.connect(buyer).approveSale(1)
            await transaction.wait()

            transaction = await escrow.connect(seller).approveSale(1)
            await transaction.wait()

            transaction = await escrow.connect(lender).approveSale(1)
            await transaction.wait()
        })

        it('updates approval status ', async () => {

            expect(await escrow.approval(1, buyer.address)).to.be.equal(true)
            expect(await escrow.approval(1, seller.address)).to.be.equal(true)
            expect(await escrow.approval(1, lender.address)).to.be.equal(true)
        })
    })



})
