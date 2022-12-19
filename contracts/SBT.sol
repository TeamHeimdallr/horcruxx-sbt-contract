// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISBT.sol";
import "./interfaces/IERC5192.sol";
import "./ERC721Enumerable.sol";
import "./utils/Ownable.sol";

/**
 * @dev Implementation of Soul-bounded Token
 */
contract SBT is ISBT, IERC5192, ERC721Enumerable, IERC721Receiver, Ownable {
    // Original NFT contract address before conversion.
    address private _originalNFTAddress;

    // Mapping from token ID to tokenURI
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from token ID to lock status
    mapping(uint256 => bool) private lockedTokens;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _originalNFTAddress = address(0);
    }

    /**
     * @dev set `_originalNFTAddress` before conversion.
     * @param nftAddress The NFT contract address.
     */
    function setOriginalNFTAddress(address nftAddress) public onlyOwner {
        _originalNFTAddress = nftAddress;
    }

    /**
     * @dev lock `tokenId` token so it can't be transferred.
     * @param tokenId The identifier for a token.
     *
     * Emits a {IERC5192-Locked} event.
     */
    function lock(uint256 tokenId) public override {
        _requireMinted(tokenId);

        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner nor approved");
        lockedTokens[tokenId] = true;
        emit Locked(tokenId);
    }

    /**
     * @dev unlock `tokenId` token so it can be transferred.
     * @param tokenId The identifier for a token.
     *
     * Emits a {IERC5192-Unlocked} event.
     */
    function unlock(uint256 tokenId) public override {
        _requireMinted(tokenId);

        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner nor approved");
        lockedTokens[tokenId] = false;
        emit Unlocked(tokenId);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}. Burn received NFT and Mint SBT
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public virtual override(IERC721Receiver) returns (bytes4) {
        require(_originalNFTAddress != address(0), "call setOriginalNFTAddress before transfer");
        require(
            _originalNFTAddress == _msgSender(),
            "msg.sender is not matched with the registered original nft address"
        );

        // burn received NFT
        IERC721(_msgSender()).transferFrom(address(this), address(0x000000000000000000000000000000000000dEaD), tokenId);

        // mint SBT
        _safeMint(from, tokenId);

        // copy token uri
        _setTokenURI(tokenId, IERC721Metadata(_msgSender()).tokenURI(tokenId));

        return this.onERC721Received.selector;
    }

    /**
     * @dev Returns original nft contract address
     */
    function originalNFTAddress() public view returns (address) {
        return _originalNFTAddress;
    }

    /**
     * @dev Returns the locking status of an Soulbound Token
     * @param tokenId The identifier for an SBT.
     */
    function locked(uint256 tokenId) public view override returns (bool) {
        return lockedTokens[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(ISBT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns tokenURI of an Soulbound Token.
     * @param tokenId The identifier for an SBT.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev set TokenURI for given Soulbound Token
     * @param tokenId The identifier for an SBT.
     * @param _tokenURI The tokenURI for an SBT.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _requireMinted(tokenId);

        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        require(!lockedTokens[tokenId], "Token is Soul bounded");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {ERC721-_safeMint}.
     * Emits a {IERC5192-Locked} event.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual override(ERC721) {
        super._safeMint(to, tokenId, data);

        // default lock status is 'locked'
        lockedTokens[tokenId] = true;
        emit Locked(tokenId);
    }
}
