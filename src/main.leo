import credits.leo;

program nft_store.aleo {
    record Token {
        owner: address,
        id: TokenId,
        data: TokenData
    }

    struct TokenId {
        token_number: u128,
        collection_number: u128
    }

    struct TokenData {
        metadata_uri: String64,
        transferable: bool
    }

    record Collection {
        owner: address,
        id: CollectionId,
        data: CollectionData
    }

    struct CollectionId {
        collection_number: u128
    }

    struct CollectionData {
        updatable: bool
    }

    struct CollectionPublicData {
        royalty_fees: u64,
        royalty_address: address,
        metadata_uri: String64,
        base_uri: String64,
        publicizable: bool
    }

    struct CollectionMintId {
        collection_number: u128,
        mint_number: u128
    }

    struct MintData {
        whitelist: bool,
        price: u64,
        treasury: address,
        start: u32,
        end: u32,
        random: bool
    }

    struct AddressCollectionMintId {
        addr: address,
        collection_number: u128,
        mint_number: u128
    }

    struct TokenMintId {
        collection_number: u128,
        token_number: u128,
        mint_number: u128
    }

    struct IndexCollectionMintId {
        index: u128,
        collection_number: u128,
        mint_number: u128
    }

    struct String64 {
        part0: u128,
        part1: u128,
        part2: u128,
        part3: u128,
    }

    struct Listing {
        seller: address,
        price: u64,
    }

    record CollectionOwnerProof {
        owner: address,
        prover: address,
        id: CollectionId,
        is_owner: bool,
        height: u32
    }

    record CollectionHolderProof {
        owner: address,
        prover: address,
        id: CollectionId,
        is_holder: bool,
        height: u32
    }

    record TokenOwnerProof {
        owner: address,
        prover: address,
        id: TokenId,
        is_owner: bool,
        height: u32
    }

    mapping collectionPublicData: CollectionId => CollectionPublicData;
    mapping tokenExists: TokenId => bool;
    mapping publicTokenData: TokenId => TokenData;
    mapping publicTokenOwners: TokenId => address;
    mapping mintWhitelists: AddressCollectionMintId => u64;
    mapping collectionMintData: CollectionMintId => MintData;
    mapping tokenMintData: TokenMintId => TokenData;
    mapping mintTokenNumbers: IndexCollectionMintId => u128;
    mapping mintLengths: CollectionMintId => u128;
    mapping listings: TokenId => Listing;

    transition create_collection(
        private collection_number: u128, 
        private collection_data: CollectionData,
        public collection_public_data: CollectionPublicData,
    ) -> private Collection {
        assert_neq(collection_number, 0u128);
        let collection_id: CollectionId = CollectionId {
            collection_number: collection_number
        };

        let collection: Collection = Collection {
            owner: self.caller,
            id: collection_id,
            data: collection_data
        };
        return collection then finalize(
            collection_id, 
            collection_public_data
        );
    }
    finalize create_collection(
        public collection_id: CollectionId,
        public collection_public_data: CollectionPublicData
    ) {
        let collection_exists: bool = collectionPublicData.contains(
            collection_id
        );
        assert(collection_exists.not());

        collectionPublicData.set(collection_id, collection_public_data);
    }

    transition update_collection_public_data(
        private collection: Collection,
        public collection_public_data: CollectionPublicData
    ) -> private Collection {
        let out_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: collection.data
        };
        return out_collection then finalize(
            collection.id, 
            collection_public_data
        );
    }
    finalize update_collection_public_data(
        public collection_id: CollectionId, 
        public collection_public_data: CollectionPublicData
    ){
        let former_collection_public_data: CollectionPublicData 
            = collectionPublicData.get(
                collection_id
            );
        assert_eq(
            former_collection_public_data.publicizable,
            collection_public_data.publicizable
        );
        collectionPublicData.set(collection_id, collection_public_data);
    }

    transition transfer_collection(
        private collection: Collection,
        private receiver: address
    ) -> private Collection {
        let out_collection: Collection = Collection {
            owner: receiver,
            id: collection.id,
            data: collection.data
        };
        return out_collection;
    }

    transition freeze_collection_updates(
        private collection: Collection
    ) -> private Collection {
        let out_collection_data: CollectionData = CollectionData {
            updatable: false
        };
        let out_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: out_collection_data
        };
        return out_collection then finalize(
            collection.id
        );
    }
    finalize freeze_collection_updates(
        public collection_id: CollectionId
    ) {
        assert(true);
    }

    transition mint_private(
        private collection: Collection, 
        public token_number: u128,
        private receiver: address,
        private token_data: TokenData
    ) -> (private Token, private Collection) {
        let new_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: collection.data
        };
        let token_id: TokenId = TokenId {
            collection_number: collection.id.collection_number,
            token_number: token_number
        };

        let token : Token = Token {
            owner: receiver,
            id: token_id,
            data: token_data
        };
        return (token, new_collection) then finalize(token_id);
    }
    finalize mint_private(
        public token_id: TokenId,
    ) {
        let token_exists: bool = tokenExists.contains(token_id);
        assert(token_exists.not());

        tokenExists.set(token_id, true);
    }

    transition burn_private(
        private collection: Collection,
        private token: Token
    ) -> private Collection {
        assert_eq(token.id.collection_number, collection.id.collection_number);
        assert(collection.data.updatable);

        let collection_data: CollectionData = CollectionData {
            updatable: collection.data.updatable,
        };

        let new_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: collection_data
        };

        return new_collection then finalize(
            token.id
        );
    }
    finalize burn_private(
        public token_id: TokenId
    ) {
        tokenExists.remove(token_id);
    }

    transition burn_public (
        private collection: Collection,
        public token_id: TokenId
    ) -> private Collection {
        assert_eq(token_id.collection_number, collection.id.collection_number);
        assert(collection.data.updatable);

        let new_collection: Collection = Collection {
            owner: collection.owner,
            id: collection.id,
            data: collection.data
        };
        return new_collection then finalize(
            token_id
        );
    }
    finalize burn_public(
        public token_id: TokenId
    ) {
        tokenExists.remove(token_id);
    }

    transition prove_collection_ownership(
        private collection: Collection,
        private prover: address
    ) -> CollectionOwnerProof {
        return CollectionOwnerProof {
            owner: collection.owner,
            prover: prover,
            id: collection.id,
            is_owner: collection.owner == prover,
            height: block.height
        };
    }

    transition prove_token_ownership(
        private token: Token,
        private prover: address
    ) -> TokenOwnerProof {
        return TokenOwnerProof {
            owner: token.owner,
            prover: prover,
            id: token.id,
            is_owner: token.owner == prover,
            height: block.height
        };
    }

    transition prove_collection_holdership(
        private collection: Collection,
        private prover: address
    ) -> CollectionHolderProof {
        return CollectionHolderProof {
            owner: collection.owner,
            prover: prover,
            id: collection.id,
            is_holder: tokenExists.keys()
                .filter(key => {
                    TokenId {
                        collection_number: collection.id.collection_number,
                        token_number: 0u128
                    }
                })
                .filter(key => tokenExists.get(key))
                .map(key => publicTokenOwners.get(key))
                .contains(prover),
            height: block.height
        };
    }

    transition mint_collection(
        private collection: Collection,
        private token_number: u128,
        private token_data: TokenData
    ) -> private Token {
        let token_id: TokenId = TokenId {
            collection_number: collection.id.collection_number,
            token_number: token_number
        };

        let token: Token = Token {
            owner: self.caller,
            id: token_id,
            data: token_data
        };
        return token then finalize(
            token_id
        );
    }
    finalize mint_collection(
        public token_id: TokenId
    ) {
        let token_exists: bool = tokenExists.contains(token_id);
        assert(token_exists.not());

        let public_token_data: TokenData = publicTokenData.get(token_id);
        assert_eq(public_token_data, token_id.data);
        tokenExists.set(token_id, true);
        publicTokenOwners.set(token_id, self.caller);
    }

    transition create_listing(
        private token: Token,
        private price: u64
    ) {
        let listing: Listing = Listing {
            seller: self.caller,
            price: price
        };
        listings.set(token.id, listing);
    }

    transition cancel_listing(
        private token: Token
    ) {
        let listing_exists: bool = listings.contains(token.id);
        assert(listing_exists);

        listings.remove(token.id);
    }

    transition buy_token(
        private token: Token
    ) {
        let listing: Listing = listings.get(token.id);
        assert(listing.seller != self.caller);

        let token_owner: address = token.owner;
        let payment: u64 = listing.price;
        self.pay(token_owner, payment);
        token.owner = self.caller;

        publicTokenOwners.set(token.id, self.caller);

        listings.remove(token.id);
    }

    transition remove_listing (
        private token: Token
    ) {
        assert_eq(token.owner, self.caller);
        listings.remove(token.id);
    }
    
    transition create_listing(
        public token_id: TokenId,
        public price: u64
    ) {
        return then finalize(self.caller, token_id, price);
    }
    finalize create_listing (
        public seller: address,
        public token_id: TokenId,
        public price: u64
    ) {
        let token_owner: address = publicTokenOwners.get(token_id);
        assert_eq(token_owner, seller);

        let token_data: TokenData = publicTokenData.get(token_id);
        assert(token_data.transferable);

        let listing: Listing = Listing {
            seller: seller,
            price: price
        };
        listings.set(token_id, listing);
        publicTokenOwners.remove(token_id);
    }

    transition update_listing (
        public token_id: TokenId,
        public price: u64
    ) {
        return then finalize(self.caller, token_id, price);
    }
    finalize update_listing (
        public seller: address,
        public token_id: TokenId,
        public price: u64
    ) {
        let listing: Listing = listings.get(token_id);
        assert_eq(seller, listing.seller);
        let new_listing: Listing = Listing {
            seller: seller,
            price: price
        };
        listings.set(token_id, new_listing);
    }

    transition cancel_listing(
        public token_id: TokenId
    ) {
        return then finalize(self.caller, token_id);
    }
    finalize cancel_listing(
        public seller: address,
        public token_id: TokenId
    ) {
        let listing: Listing = listings.get(token_id);
        assert_eq(seller, listing.seller);
        publicTokenOwners.set(token_id, seller);
        listings.remove(token_id);
    }

    transition accept_listing(
        public listing: Listing,
        private payment: credits.leo/credits,
        public royalty_fees: u64,
        public royalty_address: address,
        public token_id: TokenId,
        public token_data: TokenData
    ) -> (
        private Token, 
        credits.leo/credits, 
        credits.leo/credits, 
        credits.leo/credits, 
        credits.leo/credits
    ) {
        let token: Token = Token {
            owner: self.caller,
            id: token_id,
            data: token_data
        };
        let price: u64 = listing.price;
        let royality_amount: u64 = (royalty_fees * price).div(10000u64);
        let market_amount: u64 = (market_fees() * price).div(10000u64);
        let seller_amount: u64 = price - royality_amount - market_amount;
        
        let (out_market, payment1): (credits, credits) 
            = credits.leo/transfer_private(
                payment,
                market_fees_address(),
                market_amount
            );
        let (out_royalties, payment2) : (credits, credits) 
            = credits.leo/transfer_private(
                payment1,
                royalty_address,
                royality_amount
            );
        let (out_seller, out_buyer): (credits, credits) 
            = credits.leo/transfer_private(
                payment2,
                listing.seller,
                seller_amount
            );
        return (
            token, 
            out_market, 
            out_royalties,
            out_buyer,
            out_seller
        ) then finalize(
            listing,
            token_id,
            token_data,
            royalty_fees,
            royalty_address
        );
    }
    finalize accept_listing(
        public listing: Listing,
        public token_id: TokenId,
        public token_data: TokenData,
        public royalty_fees: u64,
        public royalty_address: address,
    ) {
        let retrieved_listing: Listing = listings.get(token_id);
        assert_eq(listing, retrieved_listing);

        let retrieved_token_data: TokenData = publicTokenData.get(token_id);
        assert_eq(token_data, retrieved_token_data);

        let collection_id: CollectionId = CollectionId {
            collection_number: token_id.collection_number
        };
        let collection_public_data: CollectionPublicData 
            = collectionPublicData.get(collection_id);
        assert_eq(
            collection_public_data.royalty_fees, royalty_fees
        );
        assert_eq(
            collection_public_data.royalty_address, royalty_address
        );
        listings.remove(token_id);
        publicTokenData.remove(token_id);
    }

    inline new_string64() -> String64 {
        return String64 {
            part0: 0u128,
            part1: 0u128,
            part2: 0u128,
            part3: 0u128
        };
    }
    inline new_address() -> address {
        return aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc;
    }
    inline new_collection_id() -> CollectionId {
        return CollectionId {
            collection_number: 0u128
        };
    }
    inline new_collection_public_data() -> CollectionPublicData {
        return CollectionPublicData {
            royalty_fees: 0u64,
            royalty_address: new_address(),
            metadata_uri: new_string64(),
            base_uri: new_string64(),
            publicizable: true,
        };
    }
    inline market_fees_address() -> address {
        return aleo1xg4897p9ea8cd4cqpm2fzq9nthjr8caa377u3a3jqv9ff9u4f5gq3kut0m;
    }
    inline market_fees() -> u64 {
        return 250u64;
    }
    inline block_height_threshold() -> u32 {
        return 50u32;
    }
}
