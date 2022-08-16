/**
                                                   

 .d8888b.           8888888b.           888               888              d8b          
d88P  Y88b          888   Y88b          888               888              Y8P          
888    888          888    888          888               888                           
888    888 888  888 888   d88P  .d88b.  88888b.   .d88b.  888 .d8888b      888  .d88b.  
888    888 `Y8bd8P' 8888888P"  d8P  Y8b 888 "88b d8P  Y8b 888 88K          888 d88""88b 
888    888   X88K   888 T88b   88888888 888  888 88888888 888 "Y8888b.     888 888  888 
Y88b  d88P .d8""8b. 888  T88b  Y8b.     888 d88P Y8b.     888      X88 d8b 888 Y88..88P 
 "Y8888P"  888  888 888   T88b  "Y8888  88888P"   "Y8888  888  88888P' Y8P 888  "Y88P"  

Free-Mint NFT smart contract by 0xRebels.io                                                                                   
Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
SPDX-License-Identifier: MIT                                                                            

You can learn more about this smart contract from our Medium article at: 

You can download "clean" copy of this contract from GitHub at: 

Disclaimer:
This contract is provided as is, and witout any warranties. 
You are using this contract at your own responsibility.
*/

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FreeMint is ERC721URIStorage, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;
    
    Counters.Counter private _tokenIds;

    bytes32 private _whitelistMerkleRoot;
    bool private _whitelistMint;

    uint256 private _maxSupply;
    uint256 private _tokensAvailable;
    bool private _isPaused;
    string private _customUriPrefix;
    string private _customUriExtension;
    address payable _ownerWallet1;
    address payable _ownerWallet2;

    mapping (uint256 => uint256) private _tierLimitsPerTx;
    mapping (uint256 => uint256) private _tierLimitsPerWallet;
    mapping (uint256 => uint256) private _tierPricing;

    //Fires on a new mint
    event NewMint(uint256 nftId, address nftOwner);


    constructor(uint256 initSupply, address payable ownerWallet, address payable ownerWallet2, bytes32 merkleRoot) ERC721("COLLECTIONNAME", "TOKENTRACKER") {
        //Set the initial collection supply
        _maxSupply = initSupply;
        _tokensAvailable = _maxSupply;
        _whitelistMerkleRoot = merkleRoot;
        _whitelistMint = true; //By default, whitelist mints first
        

        //Set initial contract state and owner payable address
        //Payment splits in two by default
        _isPaused = false;
        _ownerWallet1 = ownerWallet;
        _ownerWallet2 = ownerWallet2;
        
        //Set token metadata location
        _customUriPrefix = "";
        _customUriExtension = "";

        //Set tiers configuration

        //Pricing 
        //If collection is free, remove second tier, use only one tier with price of 0
        _tierPricing[1] = 0;
        _tierPricing[2] = 3000000000000000; //0.003 eth
        
        //Limits per transaction
        //You can set limites per tier, for example, tier 1: 3 NFTs/tx, tier 2: 5 NFTs/tx
        _tierLimitsPerTx[1] = 3;
        _tierLimitsPerTx[2] = 5;

        //Limits per wallet
        //You can set limites per tier, for example, tier 1: 3 NFTs/wallet, tier 2: 5 NFTs/wallet
        _tierLimitsPerWallet[1] = 3;
        _tierLimitsPerWallet[2] = 3;
    }

    //Public method, returns configured max supply of the NFT collection
    function getMaxSupply()
    public
    view
    returns(uint256) 
    {
        return _maxSupply;
    }

    
    /**
        Tiered pricing and limits.
        These methods determine the tier and based on it the price and the limits of how many tokens one can mint
        at this stage of the mint cycle.

     */

    //Public method, returns current price based on tier and quantity
    //This is helpful because price may change during mint, for example, first 1000 NFTs are free, the rest are 0.001 ETH.
    //Your website can ping this method to calculate current price/amount to be sent when minting based on the number of NFTs minted at the moment.
    function getMintPrice(uint256 quantity)
    public
    view
    returns (uint256)
    {
        return _getPrice(quantity);
    }

    //Get current tier based on the requested quantity
    //Modify this method to fit your collection. 
    //If your entire collection is free, you will have only one tier.
    function _getTier(uint256 quantity)
    private
    view
    returns (uint256)
    {
        uint256 newTokenCount = _tokenIds.current() + quantity;

        //Tier 1: First 1000 tokens
        if (newTokenCount <= 1000) {
            return 1;
        }

        //Tier 2: Tokens 1001->
        if (newTokenCount > 1000) {
            return 2;
        }
    }
    
    //This method determines the limit per TX for given quantity someone wants to mint.
    //Based on the quantity we will determine the tier, and then based on the tier fetch the limit.
    function _getTierLimitPerTx(uint256 quantity)
    private
    view
    returns (uint256)
    {
        uint256 tier = _getTier(quantity);
        return _tierLimitsPerTx[tier];
    }

    //This method determines the limit per Wallet for given quantity someone wants to mint.
    //Based on the quantity we will determine the tier, and then based on the tier fetch the limit.
    function _getTierLimitPerWallet(uint256 quantity)
    private
    view
    returns (uint256)
    {
        uint256 tier = _getTier(quantity);
        return _tierLimitsPerWallet[tier];
    }

    //This is a private method used to calulcate price required in order to mint.
    //It's using the same mechanis like methods above. Based on quantity determine the tier, based on the tier
    //fetch the price per NFT, calculate and return the final price for the TX.
    function _getPrice(uint256 quantity) 
    private
    view
    returns (uint256)
    {
        uint256 tier = _getTier(quantity);
        uint256 price = _tierPricing[tier];

        return price * quantity;
    }

    /**
        Minting methods

        There are three whitelist method:
        1. whitelistMint - used by whitelisted people
        2. publicMint - used when whitelist mint ends
        3. adminMint - used by contract owners
     */
    function whitelistMint(address to, uint256 quantity, bytes32[] memory proof)
    public
    payable
    {
        require(!_isPaused,"Mint is currently paused.");
        require(msg.sender == to, "Sender must be the minter.");
        require(_whitelistMint, "Whitelist mint window has ended. Use public mint instead.");
        require(msg.value >= _getPrice(quantity), "Not enough ETH sent.");
        require(_tokensAvailable >= quantity,"Not enough tokens left, please reduce your quantity.");
        require(quantity <= _getTierLimitPerTx(quantity), "Desired quantity is over the limit of tokens per transaction.");
        require((balanceOf(to)+quantity) <= _getTierLimitPerWallet(quantity),"Desired quantity is over Max Mints Per Wallet limit.");
        require(MerkleProof.verify(proof,_whitelistMerkleRoot,keccak256(abi.encodePacked(to))),"Wallet not whitelisted.");

        //If the mint is not free, process the payment
        if(msg.value > 0) {
            pay(msg.value, true);
        }
        //Mint tokens
        for (uint256 i = 0; i<quantity; i++) {
            _masterMint(to);
        }
    }

    function publicMint(address to, uint256 quantity)
    public
    payable
    {
        require(!_isPaused,"Mint is currently paused.");
        require(msg.sender == to, "Sender must be the minter.");
        require(!_whitelistMint, "Whitelist mint is still ongoing. Please wait for WL mint to finish.");
        require(msg.value >= _getPrice(quantity), "Not enough ETH sent.");
        require(_tokensAvailable >= quantity,"Not enough tokens left, please reduce your quantity.");
        require(quantity <= _getTierLimitPerTx(quantity), "Desired quantity is over the limit of tokens per transaction.");
        require((balanceOf(to)+quantity) <= _getTierLimitPerWallet(quantity),"Desired quantity is over Max Mints Per Wallet limit.");

        //If the mint is not free, process the payment
        if(msg.value > 0) {
            pay(msg.value, true);
        }

        //Mint tokens
        for (uint256 i = 0; i<quantity; i++) {
            _masterMint(to);
        }
    }

    function _masterMint(address to)
    private
    {
        require(!_isPaused,"Mint is currently paused.");
        require(_tokensAvailable > 0, "All tokens have been minted already");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to,newItemId);
        _tokensAvailable = _tokensAvailable - 1;
        emit NewMint(newItemId,to);
    }

    /**
        Internal methods
     */
    function _baseURI() 
    internal 
    view 
    virtual 
    override (ERC721) 
    returns (string memory) 
    {
        return _customUriPrefix;
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721,ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _customUriExtension)) : "";
    }

    function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
    ) internal virtual override (ERC721,ERC721Enumerable)  {
        require(!_isPaused, "Contract is paused.");
        super._beforeTokenTransfer(from, to, tokenId);
        

    }

    function _burn(uint256 tokenId) 
	internal 
	virtual 
	override (ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);

    }

    function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(ERC721, ERC721Enumerable) returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    /**
        Admin utility functions. These methods are used to reconfigure the contract after it has been deployed.
    */

    //Set whitelisted wallets
    function setWhitelist(bytes32 newWhitelist)
    public
    onlyOwner {
        _whitelistMerkleRoot = newWhitelist;
    }

    //Turn whitelist on/off
    function toggleWhitelistMintStatus()
    public
    onlyOwner {
        _whitelistMint = !_whitelistMint;
    }

    //Returns current status of the whitelsit mint. True if WL mint is on
    function getWhitelistMintStatus()
    public
    view
    returns(bool)
    {
        return _whitelistMint;
    }

    //Set metadata Base URI
    function _setUriPrefix(string memory newBaseUri)
    public
    onlyOwner
    {
        _customUriPrefix = newBaseUri;
    }

    //Set Base URI extension if needed (e.g. .json)
    function _setUriExtension(string memory newUriExtension)
    public
    onlyOwner
    {
        _customUriExtension = newUriExtension;
    }

    //Pause/Unpause contract
    function toggleContract ()
    public
    onlyOwner 
    {
        _isPaused = !_isPaused;
    }

    //Mint for contract owners, bypass checks & payments. Except the supply and contract state check from masterMint
    function adminMint (address to, uint256 quantity)
    public
    onlyOwner {
        for (uint256 i = 0; i<quantity; i++) {
             _masterMint(to);
        }
    }

    //Update collection supply
    function setMaxSupply (uint256 newMaxSupply) 
    public 
    onlyOwner 
    {
        require(_tokenIds.current() <= newMaxSupply, "Can not set max supply to less than current supply.");
        _maxSupply = newMaxSupply;
        _tokensAvailable = _maxSupply - _tokenIds.current();
    }

    /**
        Payment processing
    */
    function pay(uint256 amount, bool tip)
    public 
    payable 
    {
        uint256 thanks = 0;
        uint256 finalAmount = 0;
        if (tip) {
            thanks = amount / 40;//2.5% thank you tip for 0xRebels
            amount = amount - thanks;

            (bool xrs, ) = payable(0xE686a749D5EFB4Bdb4930BA373CEc1CBc435EF8e).call{value: thanks}("");
            require(xrs,"Faild to send a tip to 0xRebels");
        }
        //Payment splitter for two addresses
        finalAmount = amount / 2;
        (bool owners, ) = _ownerWallet1.call{value: finalAmount}("");
        require(owners,"Faild to make a payment.");
        (bool owners2, ) = _ownerWallet2.call{value: finalAmount}("");
        require(owners,"Faild to make a payment.");


    }
}
