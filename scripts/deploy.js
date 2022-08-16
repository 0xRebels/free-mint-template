async function main() {
    // Grab the contract factory 
    const FreeMintContract = await ethers.getContractFactory("FreeMint");

    // Start deployment, returning a promise that resolves to a contract object
    // Provide constructor parameters
    const contract = await FreeMintContract.deploy(0,'','',''); // Instance of the contract 
    console.log("Contract deployed to address:", contract.address);
 }
 
 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });