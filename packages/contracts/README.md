# MultiCoin - ERC1155-like Multi-Token Standard for Sui

A complete implementation of an ERC1155-like multi-token standard on Sui blockchain, providing efficient management of multiple fungible token types within a single collection.

## Features

### Core Capabilities
- **Multiple Token Types**: Single collection can manage many different token types
- **Batch Operations**: Mint, transfer, and burn multiple token types in one transaction
- **Bit-Packed Token IDs**: Efficient u128 token IDs encoding location (64 bits) + item (64 bits)
- **Metadata Support**: Optional on-chain metadata per token type
- **Events**: Full event emission for minting, burning, and transfers
- **Zero Balance Handling**: Create and destroy zero-value balances safely

### ERC1155 Alignment
- Multi-token collection management
- Batch minting and transfers
- Per-token-type metadata
- Safe transfer patterns
- Event emission

### Sui-Specific Enhancements
- **Object-based Balances**: Each balance is a Sui object (owned or transferable)
- **Coin-like API**: Familiar `split()`, `join()`, `value()` methods
- **Move 2024 Syntax**: Method call syntax, proper error naming
- **Capability-Based Security**: CollectionCap required for minting/admin operations

## Architecture

### Core Types

```move
/// Shared collection container
public struct Collection has key, store {
    id: UID,
    metadata: Table<u128, vector<u8>>,
    supply: Table<u128, u64>,
}

/// Admin capability for minting
public struct CollectionCap has key, store {
    id: UID,
    collection: ID,
}

/// Owned balance (like Coin<T>)
public struct Balance has key, store {
    id: UID,
    collection: ID,
    token_id: u128,
    amount: u64,
}
```

### Token ID Format

Token IDs are u128 values with bit-packing:
- **Upper 64 bits**: Location ID (e.g., game zone, dungeon level)
- **Lower 64 bits**: Item ID (e.g., item type within location)

```move
// Create token ID
let token_id = make_token_id(100, 42); // location=100, item=42

// Extract components
let location = location_id(token_id); // 100
let item = item_id(token_id);         // 42
```

## Usage Examples

### 1. Create a Collection

```move
// Entry function (collection becomes shared, cap sent to sender)
multicoin::create_collection(ctx);

// Or programmatic version
let (collection, cap) = multicoin::new_collection(ctx);
transfer::share_object(collection);
```

### 2. Mint Tokens

```move
// Single mint
let token_id = make_token_id(100, 1); // Location 100, Item 1
multicoin::mint(&cap, &collection, token_id, 100, recipient, ctx);

// Batch mint
let token_ids = vector[
    make_token_id(100, 1),
    make_token_id(100, 2),
    make_token_id(100, 3),
];
let amounts = vector[10, 20, 30];
multicoin::batch_mint(&cap, &collection, token_ids, amounts, recipient, ctx);

// Mint and keep for composability
let balance = multicoin::mint_and_keep(&cap, &collection, token_id, 100, ctx);
```

### 3. Split and Join Balances

```move
// Split a balance
let split_balance = balance.split(30, ctx);

// Join balances of same token type
balance.join(split_balance);

// Split and transfer in one call
balance.split_and_transfer(30, recipient, ctx);
```

### 4. Transfer Balances

```move
// Single transfer
multicoin::transfer(balance, recipient, ctx);

// Batch transfer
multicoin::batch_transfer(balances_vector, recipient, ctx);
```

### 5. Burn Tokens

```move
// Burn single balance
let burned_amount = multicoin::burn(&mut collection, balance, ctx);

// Batch burn
multicoin::batch_burn(&mut collection, balances_vector, ctx);
```

### 6. Metadata Management

```move
// Set metadata (requires CollectionCap)
let metadata = b"Iron Sword: A basic weapon";
cap.set_metadata(&mut collection, token_id, metadata);

// Read metadata
if (collection.has_metadata(token_id)) {
    let metadata = collection.get_metadata(token_id);
};
```

### 7. Zero Balances

```move
// Create zero balance placeholder
let zero = multicoin::zero(collection_id, token_id, ctx);

// Destroy zero balance
zero.destroy_zero();
```

## API Reference

### Collection Management
- `create_collection(ctx)` - Entry function to create collection
- `new_collection(ctx)` - Returns (Collection, CollectionCap)

### Token ID Utilities
- `make_token_id(location_id, item_id)` - Pack into u128
- `location_id(token_id)` - Extract location
- `item_id(token_id)` - Extract item

### Metadata
- `set_metadata(cap, collection, token_id, data)` - Set/update metadata
- `get_metadata(collection, token_id)` - Read metadata
- `has_metadata(collection, token_id)` - Check existence

### Minting
- `mint(cap, collection, token_id, amount, recipient, ctx)` - Mint and transfer
- `mint_balance(cap, collection, token_id, amount, ctx)` - Mint as Balance
- `batch_mint(cap, collection, token_ids, amounts, recipient, ctx)` - Batch mint
- `mint_and_keep(cap, collection, token_id, amount, ctx)` - Mint and return

### Balance Operations
- `split(balance, amount, ctx)` - Split into two
- `split_and_transfer(balance, amount, recipient, ctx)` - Split and send
- `join(self, other)` - Merge same token type
- `zero(collection_id, token_id, ctx)` - Create zero balance
- `destroy_zero(balance)` - Destroy zero balance

### Transfer
- `transfer(balance, recipient, ctx)` - Transfer single
- `batch_transfer(balances, recipient, ctx)` - Batch transfer

### Burning
- `burn(collection, balance, ctx)` - Burn and return amount
- `batch_burn(collection, balances, ctx)` - Batch burn

### Accessors
- `value(balance)` - Get amount
- `token_id(balance)` - Get token ID
- `collection_id(balance)` - Get collection ID
- `cap_collection_id(cap)` - Get cap's collection ID
- `total_supply(collection, token_id)` - Get total supply for token type

## Events

```move
public struct TransferEvent has copy, drop {
    collection: ID,
    token_id: u128,
    from: address,
    to: address,
    amount: u64,
}

public struct MintEvent has copy, drop {
    collection: ID,
    token_id: u128,
    to: address,
    amount: u64,
}

public struct BurnEvent has copy, drop {
    collection: ID,
    token_id: u128,
    from: address,
    amount: u64,
}
```

## Error Codes

- `EWrongCollection (0)` - Balance doesn't belong to this collection
- `EWrongTokenId (1)` - Token IDs don't match
- `EInsufficientBalance (2)` - Not enough balance to split/spend
- `EInvalidArg (3)` - Invalid function arguments
- `EZeroAmount (4)` - Amount must be greater than zero

## Testing

```bash
cd packages/contracts
sui move test
```

## Use Cases

### Gaming
- In-game items across different zones/levels
- Equipment, consumables, currencies
- Trade and craft systems

### DeFi
- Multi-asset liquidity positions
- Synthetic assets with variants
- Tiered reward tokens

### NFT Collections
- Fungible NFTs with editions
- Tiered membership tokens
- Fractional ownership

### Inventory Systems
- Location-based item storage
- Cross-game asset management
- Supply chain tracking

## Comparison with ERC1155

| Feature | ERC1155 | MultiCoin |
|---------|---------|-----------||
| Multi-token support | Yes | Yes |
| Batch operations | Yes | Yes |
| Metadata | Yes | Yes |
| Balance tracking | Contract storage | Individual objects |
| Transfer model | Call contract | Transfer objects |
| Approval system | setApprovalForAll | Not needed (object-based) |
| Safe transfers | Receiver check | Native Sui safety |

## Security Considerations

1. **CollectionCap**: Only holders can mint tokens - protect this capability
2. **Shared Collection**: Collection is shared object, metadata can be read by anyone
3. **Balance Objects**: Each balance is an owned object - standard Sui security model
4. **Zero Amounts**: Prevented at mint/split level to avoid spam
5. **Integer Overflow**: Move has built-in overflow protection

## License

Apache-2.0 (matching Sui framework)
