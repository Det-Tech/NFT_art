// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./utils/access/Ownable.sol";
import "./ERC721/ERC721.sol";

contract ArtToken is Ownable, ERC721 {
    
    uint256 private _totalSupply;
    
    mapping(uint256 => string) private _tokenURIs;
    
    mapping(uint256 => string) private _tokenDatas;
    
    event BaseURIChange(string baseURI);

    event ItemCreated(
        address indexed owner,
        uint256 indexed tokenId
    );

    struct TokenExtraInfo {
        string metaDataURI;
        bytes32 metaDataHash;
    }

    mapping (uint256 => TokenExtraInfo) public extraInfoMap;

    // Used to correctly support fingerprint verification for the assets
    bytes4 public constant _INTERFACE_ID_ERC721_VERIFY_FINGERPRINT = bytes4(
        keccak256("verifyFingerprint(uint256,bytes32)")
    );

    constructor (
        string memory _name,
        string memory _symbol
    )
        Ownable() ERC721(_name, _symbol)
    {
        _totalSupply=0;

        // Registers
        //_registerInterface(_INTERFACE_ID_ERC721_VERIFY_FINGERPRINT);
    }

    /**
     * @dev Sets the base URI for the registry metadata
     * @param _baseUri Address for the fees collector
     */
    // function setBaseURI(string memory _baseUri) public onlyOwner {
    //     _setBaseURI(_baseUri);
    //     emit BaseURIChange(_baseUri);
    // }
    
    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }
    
    function tokenMetaData(uint256 tokenId) external view returns (string memory) {
        require((_exists(tokenId)));
        return _tokenDatas[tokenId];
    }
    
    function totalSupply()external view returns(uint256){
        return _totalSupply;
    }

    /**
     * Creates a NFT
     * @param _metaDataURI for the new token
     * @param _metaData metadata JSONified string
     */
    function create(
        string calldata _metaDataURI,
        string calldata _metaData
    )
        external
    {
        _create(msg.sender, _metaDataURI, _metaData);
    }

    /**
     * Creates a NFT
     * @param _metaDataURI for the new token
     * @param _metaData metadata JSONified string
     * @param _marketplace address
     */
    function createPub(
        string calldata _metaDataURI,
        string calldata _metaData,
        address _marketplace
    )
        external
    {
        // Create the new asset and allow marketplace to manage it
        // Use this to override the msg.sender here.
        this.approve(
            _marketplace,
            _create(address(this), _metaDataURI, _metaData)
        );

        // execute create order in destination marketplace
        // (bool success, ) = _marketplace.call(_encodedCallData);
        // require(
        //     success,
        //     "Marketplace: failed to execute publish order"
        // );
    }

    function _create(
        address _owner,
        string calldata _metaDataURI,
        string calldata _metaData
    )
        internal returns (uint256 tokenId)
    {
        tokenId = _totalSupply;
        _totalSupply=_totalSupply+1;

        /// Save data
        extraInfoMap[tokenId] = TokenExtraInfo({
            metaDataURI: _metaDataURI,
            metaDataHash: getMetaDataHash(_metaData)
        });

        /// Mint new NFT
        _mint(_owner, tokenId);
        _setTokenURI(tokenId, _metaDataURI);
        _setTokenData(tokenId,_metaData);

        emit ItemCreated(_owner, tokenId);
    }




    function getMetaDataHash(string memory _metaData) public pure returns (bytes32) {
        bytes32 msgHash = keccak256(abi.encodePacked(_metaData));

        // return prefixed hash, see: eth_sign()
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );
    }

    function verifyFingerprint(uint256 _tokenId, bytes32 _fingerprint) public view returns (bool) {
        return extraInfoMap[_tokenId].metaDataHash == _fingerprint;
    }
    
    // function _setBaseURI(string memory _baseUri) private {
        
    // }
    
    /**
     * @dev Internal function to set the token URI for a given token
     * Reverts if the token ID does not exist
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }
    
    function _setTokenData(uint256 tokenId, string memory data) internal {
        require(_exists(tokenId));
        
        _tokenDatas[tokenId] = data;
    }
    
}
