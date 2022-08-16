0xRebels.io - Free Mint NFT smart contract

This is a smart contract template for a free-mint NFT collection, but it can also be used for a tiered-pricing mint. For example, the contract can be used to set up an NFT collection where first 1,000 NFTs are free, then the next 1,000 are priced at 0.001 ETH, then the rest is priced at 0.005 ETH.

The smart contract supports MerkleTree whitelisting and is packed with a few important features such as:
- Configuring Base URI
- Admin/Owner mint
- Pause/Unpause contract
- Turn whitelist mint on/off
- Burn NFTs
- Configure collection supply
- Payment spliter
- Whitelisted wallet list update

This smart contract is provided as is, without any warranties. You are using it at your own risk.


How to get started:
1. Clode the repository
2. Run npm i inside the cloned repository directory (you must have node installed)

This will instiall hardhat and all other required modules.

Once you do this, configure the smart contract to fit your needs, and deploy to a testnet:
1. Make changes to the smart contract, configure tiers, pricing
2. Configure Etherscan, Infura and deployer key in the .env file
3. Make changes to the hardhat.config.js
4. Compile the contract by running npx hardhat compile
5. Configure constructor parameters in the scripts/deploy.js
6. Deploy the smart contract by running npx hardhat run scripts/deploy.js --network rinkeby
7. Verify the smart contract by running npx hardhat verify --network rinkeby SC_ADDRESS "SUPPLY" OWNER_WALLET1 OWNER_WALLET2 WHITELIST_MERKLE_TREE_ROOT 


When you are ready to deploy to the mainnet, update your .env, hardhat.config.js, and scripts/deploy.js files - and use the same process to deploy your contract to the mainnet.

P.S.
The payment section of the smart contract includes a completely optional symbolic 2.5% tip for our team. Feel free to remove it, although it would help maintain this repository.