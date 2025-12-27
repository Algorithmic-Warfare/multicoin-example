#[test_only]
module multicoin::multicoin_tests;

use sui::test_scenario;
use multicoin::multicoin::{Self, Collection, CollectionCap, Balance};

const ADMIN: address = @0xAD;
const USER1: address = @0x1;
const USER2: address = @0x2;

// Token IDs for testing
const SWORD_ITEM: u64 = 1;
const SHIELD_ITEM: u64 = 2;
const POTION_ITEM: u64 = 3;
const LOCATION_TOWN: u64 = 100;

#[test]
fun test_create_collection() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    {
        multicoin::create_collection(scenario.ctx());
    };
    
    scenario.next_tx(ADMIN);
    
    {
        let cap = scenario.take_from_sender<CollectionCap>();
        scenario.return_to_sender(cap);
    };
    
    scenario.end();
}

#[test]
fun test_token_id_packing() {
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    assert!(multicoin::location_id(token_id) == LOCATION_TOWN);
    assert!(multicoin::item_id(token_id) == SWORD_ITEM);
}

#[test]
fun test_mint_and_balance() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (collection, cap) = multicoin::new_collection(scenario.ctx());
    let collection_id = object::id(&collection);
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    transfer::public_share_object(collection);
    
    scenario.next_tx(ADMIN);
    
    {
        let mut collection = scenario.take_shared<Collection>();
        multicoin::mint(&cap, &mut collection, token_id, 100, USER1, scenario.ctx());
        test_scenario::return_shared(collection);
    };
    
    scenario.next_tx(USER1);
    
    {
        let balance = scenario.take_from_sender<Balance>();
        assert!(balance.value() == 100);
        assert!(balance.token_id() == token_id);
        assert!(balance.collection_id() == collection_id);
        scenario.return_to_sender(balance);
    };
    
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
fun test_split_and_join() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    let mut balance = multicoin::mint_and_keep(&cap, &mut collection, token_id, 100, scenario.ctx());
    
    let split_balance = balance.split(30, scenario.ctx());
    
    assert!(balance.value() == 70);
    assert!(split_balance.value() == 30);
    
    balance.join(split_balance);
    assert!(balance.value() == 100);
    
    transfer::public_transfer(balance, ADMIN);
    transfer::public_share_object(collection);
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
fun test_batch_mint() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (collection, cap) = multicoin::new_collection(scenario.ctx());
    transfer::public_share_object(collection);
    
    scenario.next_tx(ADMIN);
    
    {
        let mut collection = scenario.take_shared<Collection>();
        let token_ids = vector[
            multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM),
            multicoin::make_token_id(LOCATION_TOWN, SHIELD_ITEM),
            multicoin::make_token_id(LOCATION_TOWN, POTION_ITEM),
        ];
        let amounts = vector[10, 5, 20];
        
        multicoin::batch_mint(&cap, &mut collection, token_ids, amounts, USER1, scenario.ctx());
        test_scenario::return_shared(collection);
    };
    
    scenario.next_tx(USER1);
    
    {
        let ids = scenario.ids_for_sender<Balance>();
        assert!(ids.length() == 3);
    };
    
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
fun test_zero_balance() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (collection, cap) = multicoin::new_collection(scenario.ctx());
    let collection_id = object::id(&collection);
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    let zero_balance = multicoin::zero(collection_id, token_id, scenario.ctx());
    assert!(zero_balance.value() == 0);
    
    zero_balance.destroy_zero();
    
    transfer::public_share_object(collection);
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
fun test_burn() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    let balance = multicoin::mint_and_keep(&cap, &mut collection, token_id, 100, scenario.ctx());
    
    let burned_amount = multicoin::burn(&mut collection, balance, scenario.ctx());
    assert!(burned_amount == 100);
    
    transfer::public_share_object(collection);
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
fun test_metadata() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    assert!(!collection.has_metadata(token_id));
    
    let metadata = b"Iron Sword: A sturdy blade";
    cap.set_metadata(&mut collection, token_id, metadata);
    
    assert!(collection.has_metadata(token_id));
    assert!(collection.get_metadata(token_id) == &metadata);
    
    // Update metadata
    let new_metadata = b"Steel Sword: An upgraded blade";
    cap.set_metadata(&mut collection, token_id, new_metadata);
    assert!(collection.get_metadata(token_id) == &new_metadata);
    
    transfer::public_share_object(collection);
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
fun test_split_and_transfer() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    transfer::public_share_object(collection);
    
    scenario.next_tx(ADMIN);
    
    {
        let mut collection = scenario.take_shared<Collection>();
        multicoin::mint(&cap, &mut collection, token_id, 100, USER1, scenario.ctx());
        test_scenario::return_shared(collection);
    };
    
    scenario.next_tx(USER1);
    
    {
        let mut balance = scenario.take_from_sender<Balance>();
        multicoin::split_and_transfer(&mut balance, 30, USER2, scenario.ctx());
        scenario.return_to_sender(balance);
    };
    
    scenario.next_tx(USER1);
    
    {
        let balance = scenario.take_from_sender<Balance>();
        assert!(balance.value() == 70);
        scenario.return_to_sender(balance);
    };
    
    scenario.next_tx(USER2);
    
    {
        let balance = scenario.take_from_sender<Balance>();
        assert!(balance.value() == 30);
        scenario.return_to_sender(balance);
    };
    
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

#[test]
#[expected_failure(abort_code = 2)]
fun test_split_insufficient_balance() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    let mut balance = multicoin::mint_and_keep(&cap, &mut collection, token_id, 100, scenario.ctx());
    
    let _split = balance.split(101, scenario.ctx());
    
    abort 0
}

#[test]
#[expected_failure(abort_code = 1)]
fun test_join_wrong_token_id() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id1 = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    let token_id2 = multicoin::make_token_id(LOCATION_TOWN, SHIELD_ITEM);
    
    let mut balance1 = multicoin::mint_and_keep(&cap, &mut collection, token_id1, 100, scenario.ctx());
    let balance2 = multicoin::mint_and_keep(&cap, &mut collection, token_id2, 50, scenario.ctx());
    
    balance1.join(balance2);
    
    abort 0
}

#[test]
#[expected_failure(abort_code = 4)]
fun test_mint_zero_amount() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    let _balance = multicoin::mint_and_keep(&cap, &mut collection, token_id, 0, scenario.ctx());
    
    abort 0
}

#[test]
#[expected_failure(abort_code = 2)]
fun test_destroy_non_zero_balance() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    let balance = multicoin::mint_and_keep(&cap, &mut collection, token_id, 100, scenario.ctx());
    
    balance.destroy_zero();
    
    abort 0
}

#[test]
fun test_total_supply() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    let (mut collection, cap) = multicoin::new_collection(scenario.ctx());
    let token_id = multicoin::make_token_id(LOCATION_TOWN, SWORD_ITEM);
    
    // Initially supply should be 0
    assert!(multicoin::total_supply(&collection, token_id) == 0);
    
    // Mint 100 tokens
    let mut balance1 = multicoin::mint_and_keep(&cap, &mut collection, token_id, 100, scenario.ctx());
    assert!(multicoin::total_supply(&collection, token_id) == 100);
    
    // Mint 50 more tokens
    let balance2 = multicoin::mint_and_keep(&cap, &mut collection, token_id, 50, scenario.ctx());
    assert!(multicoin::total_supply(&collection, token_id) == 150);
    
    // Burn 30 tokens
    let split = balance1.split(30, scenario.ctx());
    multicoin::burn(&mut collection, split, scenario.ctx());
    assert!(multicoin::total_supply(&collection, token_id) == 120);
    
    // Clean up
    transfer::public_transfer(balance1, ADMIN);
    transfer::public_transfer(balance2, ADMIN);
    transfer::public_share_object(collection);
    transfer::public_transfer(cap, ADMIN);
    scenario.end();
}

