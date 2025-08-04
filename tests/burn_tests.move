#[test_only]
module token_rdx::token_rdx_tests;

use sui::test_scenario::{Self as ts};
use sui::coin::{Self, Coin, TreasuryCap};
use token_rdx::rdx::{RDX, mint, burn, test_init};

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests for burn function
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fun test_burn_entire_coin() {
    let user = @0x1;

    let mut scenario = ts::begin(user);
    
    // Initialize the contract
    test_init(ts::ctx(&mut scenario));

    let mint_amount = 100000000; // 1 RDX (with 8 decimals)

    // Mint 1 RDX
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Record supply after mint
    ts::next_tx(&mut scenario, user);
    let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
    let supply_after_mint = coin::total_supply(&cap);
    ts::return_shared(cap);

    // Burn the entire coin
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let coin_to_burn = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin_to_burn) == mint_amount, 0);
        burn(&mut cap, coin_to_burn);
        ts::return_shared(cap);
    };

    // Verify supply decreased
    ts::next_tx(&mut scenario, user);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let supply_after_burn = coin::total_supply(&cap);
        assert!(supply_after_burn == supply_after_mint - mint_amount, 1);
        ts::return_shared(cap);
    };

    ts::end(scenario);
}

#[test]
fun test_burn_multiple_coins() {
    let user = @0x1;
    let mut scenario = ts::begin(user);
    
    // Initialize the contract
    test_init(ts::ctx(&mut scenario));
    
    let first_amount = 50_000_000; // 0.5 RDX
    let second_amount = 30_000_000; // 0.3 RDX

    // Mint first coin
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, first_amount, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Mint second coin
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, second_amount, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Record total supply after mints
    ts::next_tx(&mut scenario, user);
    let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
    let supply_after_mints = coin::total_supply(&cap);
    ts::return_shared(cap);

    // Burn first coin
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let first_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        burn(&mut cap, first_coin);
        ts::return_shared(cap);
    };

    // Burn second coin
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let second_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        burn(&mut cap, second_coin);
        ts::return_shared(cap);
    };

    // Verify both coins were burned
    ts::next_tx(&mut scenario, user);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let final_supply = coin::total_supply(&cap);
        assert!(final_supply == supply_after_mints - first_amount - second_amount, 2);
        ts::return_shared(cap);
    };

    ts::end(scenario);
}

#[test]
fun test_burn_zero_value_coin() {
    let user = @0x1;
    let mut scenario = ts::begin(user);
    
    // Initialize the contract
    test_init(ts::ctx(&mut scenario));

    // Record initial supply
    ts::next_tx(&mut scenario, user);
    let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
    let initial_supply = coin::total_supply(&cap);
    ts::return_shared(cap);

    // Mint 0 RDX
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, 0, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Burn the zero-value coin
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let zero_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&zero_coin) == 0, 3);
        burn(&mut cap, zero_coin);
        ts::return_shared(cap);
    };

    // Verify supply unchanged
    ts::next_tx(&mut scenario, user);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let final_supply = coin::total_supply(&cap);
        assert!(final_supply == initial_supply, 4);
        ts::return_shared(cap);
    };

    ts::end(scenario);
}