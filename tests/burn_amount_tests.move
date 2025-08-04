#[test_only]
module token_rdx::burn_amount_tests;

// Import test framework for blockchain simulation
use sui::test_scenario::{Self as ts};
// Import coin functionality and treasury for supply management
use sui::coin::{Self, TreasuryCap};
// Import our token functions and error constants
use token_rdx::rdx::{RDX, mint, burn_amount, test_init, E_AMOUNT_ZERO};

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests for burn_amount function (partial burning)
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fun test_burn_amount_partial() {
    // Test burning a partial amount while keeping remainder
    let alice = @0x1;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let mint_amount = 100_000_000;  // 1 RDX total
    let burn_amount = 30_000_000;   // Burn 0.3 RDX
    let expected_remainder = mint_amount - burn_amount; // 0.7 RDX left
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Get initial total supply before burning
    let initial_supply;
    ts::next_tx(&mut scenario, alice);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        initial_supply = coin::total_supply(&cap);
        ts::return_shared(cap);
    };

    // Alice burns partial amount (the function transfers remainder back to alice)
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let coin = ts::take_from_sender<sui::coin::Coin<RDX>>(&scenario);
        
        // Verify coin has full amount before burning
        assert!(coin::value(&coin) == mint_amount, 0);
        
        // Burn partial amount (this will automatically send remainder back to Alice)
        burn_amount(&mut cap, coin, burn_amount, ts::ctx(&mut scenario));
        
        ts::return_shared(cap);
    };

    // Verify Alice received the remainder coin
    ts::next_tx(&mut scenario, alice);
    {
        let remainder_coin = ts::take_from_sender<sui::coin::Coin<RDX>>(&scenario);
        assert!(coin::value(&remainder_coin) == expected_remainder, 1);
        ts::return_to_sender(&scenario, remainder_coin);
    };

    // Verify total supply decreased by burned amount
    ts::next_tx(&mut scenario, alice);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let final_supply = coin::total_supply(&cap);
        let expected_supply = initial_supply - burn_amount;
        assert!(final_supply == expected_supply, 2);
        ts::return_shared(cap);
    };

    ts::end(scenario);
}

#[test]
fun test_burn_amount_entire_coin() {
    // Test burning the entire coin amount (should behave like burn)
    let alice = @0x1;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let mint_amount = 75_000_000; // 0.75 RDX
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Get initial supply
    let initial_supply;
    ts::next_tx(&mut scenario, alice);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        initial_supply = coin::total_supply(&cap);
        ts::return_shared(cap);
    };

    // Alice burns entire coin
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let coin = ts::take_from_sender<sui::coin::Coin<RDX>>(&scenario);
        
        // Burn entire amount
        burn_amount(&mut cap, coin, mint_amount, ts::ctx(&mut scenario));
        
        ts::return_shared(cap);
    };

    // Verify total supply decreased by full amount
    ts::next_tx(&mut scenario, alice);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let final_supply = coin::total_supply(&cap);
        let expected_supply = initial_supply - mint_amount;
        assert!(final_supply == expected_supply, 4);
        ts::return_shared(cap);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = E_AMOUNT_ZERO)]
fun test_burn_amount_zero() {
    // Test burning zero amount (should fail with E_AMOUNT_ZERO)
    let alice = @0x1;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let mint_amount = 50_000_000; // 0.5 RDX
    let burn_amount = 0;          // Burn nothing (should fail)
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice tries to "burn" zero amount (this should fail)
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let coin = ts::take_from_sender<sui::coin::Coin<RDX>>(&scenario);
        
        burn_amount(&mut cap, coin, burn_amount, ts::ctx(&mut scenario));
        
        ts::return_shared(cap);
    };

    ts::end(scenario);
}
