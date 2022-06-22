
const contracts = [
    "LiquidityFactory",
    "testcoin1",
    "testcoin2"
]
const main = async () =>{
    const contractFactory = await hre.ethers.getContractFactory(contracts[0]);
    const factoryContract = await contractFactory.deploy();
    await factoryContract.deployTransaction.wait();

    console.log("deployed at:",factoryContract.address);
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