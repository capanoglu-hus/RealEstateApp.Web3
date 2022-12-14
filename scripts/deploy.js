const hre = require("hardhat");

const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), "ether");

}

async function main() {
    [buyer, seller, inspector, lender] = await ethers.getSigners()

    //deploy realestate 
    const RealEstate = await ethers.getContractFactory('RealEstate')
    const realEstate = await RealEstate.deploy()
    await realEstate.deployed()

    console.log(`Deployed Real Estate Contract at: ${realEstate.address}`)
    console.log('minting 3 nft ')

    // nft basmak için 
    for (let i = 0; i < 3; i++) {
        const transaction = await realEstate.connect(seller).mint("https://ipfs.io/ipfs/QmTudSYeM7mz3PkYEWXWqPjomRPHogcMFSq7XAvsvsgAPS")
        await transaction.wait()

    }

    const Escrow = await ethers.getContractFactory('Escrow')
    const escrow = await Escrow.deploy( 
        realEstate.address,
        seller.address,
        inspector.address,
        lender.address
    )

    await escrow.deployed()

    console.log(`Deployed Escrow Contract at: ${escrow.address}`)
    console.log('listing 3 prooertiess .. \n ')

    for (let i = 0; i < 3; i++) {
        let transaction = await realEstate.connect(seller).approve(escrow.address , i+1)
        await transaction.wait()
    }

    transaction = await escrow.connect(seller).list(1 , buyer.address , tokens(20) , tokens(10))
    await transaction.wait()

    transaction = await escrow.connect(seller).list(2 , buyer.address , tokens(15) , tokens(5))
    await transaction.wait()

    transaction = await escrow.connect(seller).list(3 , buyer.address , tokens(10) , tokens(5))
    await transaction.wait()

    console.log('finished.')
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;  

})
