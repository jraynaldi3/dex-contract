const { parseEther } = require("ethers/lib/utils");

const contracts = [
    "LiquidityFactory",
    "testcoin1",
    "testcoin2"
]
const main = async () =>{
    const[signer,rand1, rand2] = await hre.ethers.getSigners();
    const contractFactory = await hre.ethers.getContractFactory(contracts[0]);
    const factoryContract = await contractFactory.deploy();
    await factoryContract.deployTransaction.wait();
    console.log("deployed by:", signer.address);
    console.log("deployed at:",factoryContract.address);
    const testcoin1Factory = await hre.ethers.getContractFactory(contracts[1]);
    const testcoin2Factory = await hre.ethers.getContractFactory(contracts[2]);
    const testcoin1 = await testcoin1Factory.deploy();
    const testcoin2 = await testcoin2Factory.deploy();
    console.log("COIN 1:", testcoin1.address, "Balance:", await testcoin1.balanceOf(signer.address));
    console.log("COIN 2:", testcoin2.address);
    let tx = await factoryContract.createPool(testcoin1.address,testcoin2.address);
    await tx.wait();
    const pool = await factoryContract.poolAddress(testcoin1.address,testcoin2.address);
    const poolContract = await hre.ethers.getContractAt("LiquidityPool", pool);
    tx = await testcoin2.transfer(pool, parseEther("0.5"));
    tx = await testcoin1.transfer(pool, parseEther("1"));
    console.log(await poolContract.getCurrentPrice())
    tx = await testcoin1.approve(pool,parseEther("1"));
    tx = await testcoin2.approve(pool,parseEther("1"));
    tx = await poolContract.addLiquidity(parseEther("0.5"),parseEther("0.25"));
    console.log(await poolContract.getCurrentPrice());
}

const runMain = async()=>{
    try{
        await main();
        process.exit(0);
    } catch(error){
        console.error(error);
        process.exit(1);
    }
}

runMain();