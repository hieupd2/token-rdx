#[test_only]
module token_rdx::mint_tests;

// Import the test scenario framework for simulating blockchain transactions
use sui::test_scenario::{Self as ts};
// Import coin-related types and functions for working with tokens
use sui::coin::{Self, Coin, TreasuryCap};
// Import our RDX token module and its functions
use token_rdx::rdx::{RDX, mint, test_init};

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests for mint function
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fun test_mint_basic_amount() {
    // Set up a test user address
    let user = @0x1;
    // Create a new test scenario starting with the user
    let mut scenario = ts::begin(user);
    
    // Initialize the contract (creates and shares the TreasuryCap)
    test_init(ts::ctx(&mut scenario));
    
    // Define the amount to mint (1 RDX with 8 decimals = 100,000,000)
    let mint_amount = 100_000_000;
    
    // Move to the next transaction in the scenario
    ts::next_tx(&mut scenario, user);
    {
        // Take the shared TreasuryCap from the scenario
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        // Call the mint function to create new tokens and send them to the user
        mint(&mut cap, mint_amount, user, ts::ctx(&mut scenario));
        // Return the TreasuryCap back to the shared pool
        ts::return_shared(cap);
    };

    // Move to next transaction to verify the mint worked
    // (Required: coins are only available to take_from_sender after transaction completion)
    ts::next_tx(&mut scenario, user);
    {
        // Take the coin that should have been sent to the user
        let minted_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        // Verify the coin has the correct value
        assert!(coin::value(&minted_coin) == mint_amount, 0);
        // Return the coin to the user (cleanup)
        ts::return_to_sender(&scenario, minted_coin);
    };

    // Clean up the test scenario
    ts::end(scenario);
}

#[test]
fun test_mint_zero_amount() {
    // Test minting zero tokens (edge case)
    let user = @0x1;
    let mut scenario = ts::begin(user);
    
    // Initialize the contract
    test_init(ts::ctx(&mut scenario));
    
    // Mint 0 tokens
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, 0, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Verify a zero-value coin was created
    ts::next_tx(&mut scenario, user);
    {
        let zero_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        // Assert the coin value is indeed zero
        assert!(coin::value(&zero_coin) == 0, 1);
        ts::return_to_sender(&scenario, zero_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_mint_large_amount() {
    // Test minting a very large amount of tokens
    let user = @0x1;
    let mut scenario = ts::begin(user);
    
    test_init(ts::ctx(&mut scenario));
    
    // Mint 1 billion RDX tokens (1,000,000,000 * 10^8)
    let large_amount = 100_000_000_000_000_000;
    
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, large_amount, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Verify the large amount was minted correctly
    ts::next_tx(&mut scenario, user);
    {
        let large_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&large_coin) == large_amount, 2);
        ts::return_to_sender(&scenario, large_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_mint_to_different_recipients() {
    // Test minting tokens to different users
    let minter = @0x1;  // The user who calls mint
    let alice = @0x2;   // First recipient
    let bob = @0x3;     // Second recipient
    
    let mut scenario = ts::begin(minter);
    
    test_init(ts::ctx(&mut scenario));
    
    let alice_amount = 50_000_000;  // 0.5 RDX
    let bob_amount = 75_000_000;    // 0.75 RDX
    
    // Mint tokens for Alice
    ts::next_tx(&mut scenario, minter);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, alice_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };
    
    // Mint tokens for Bob
    ts::next_tx(&mut scenario, minter);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, bob_amount, bob, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Verify Alice received her tokens
    ts::next_tx(&mut scenario, alice);
    {
        let alice_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&alice_coin) == alice_amount, 3);
        ts::return_to_sender(&scenario, alice_coin);
    };

    // Verify Bob received his tokens
    ts::next_tx(&mut scenario, bob);
    {
        let bob_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&bob_coin) == bob_amount, 4);
        ts::return_to_sender(&scenario, bob_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_mint_multiple_times_same_user() {
    // Test minting multiple separate coins to the same user
    let user = @0x1;
    let mut scenario = ts::begin(user);
    
    test_init(ts::ctx(&mut scenario));
    
    let first_mint = 30_000_000;   // 0.3 RDX
    let second_mint = 20_000_000;  // 0.2 RDX
    let third_mint = 10_000_000;   // 0.1 RDX
    
    // First mint
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, first_mint, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };
    
    // Second mint
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, second_mint, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };
    
    // Third mint
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, third_mint, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Verify all three coins were received (test framework creates separate coin objects)
    ts::next_tx(&mut scenario, user);
    {
        // Take first coin
        let coin1 = ts::take_from_sender<Coin<RDX>>(&scenario);
        let value1 = coin::value(&coin1);
        
        // Take second coin
        let coin2 = ts::take_from_sender<Coin<RDX>>(&scenario);
        let value2 = coin::value(&coin2);
        
        // Take third coin
        let coin3 = ts::take_from_sender<Coin<RDX>>(&scenario);
        let value3 = coin::value(&coin3);
        
        // Verify total value equals all mints (order might vary)
        let total_value = value1 + value2 + value3;
        assert!(total_value == first_mint + second_mint + third_mint, 5);
        
        // Return all coins
        ts::return_to_sender(&scenario, coin1);
        ts::return_to_sender(&scenario, coin2);
        ts::return_to_sender(&scenario, coin3);
    };

    ts::end(scenario);
}

#[test]
fun test_mint_supply_increases() {
    // Test that minting increases the total supply correctly
    let user = @0x1;
    let mut scenario = ts::begin(user);
    
    test_init(ts::ctx(&mut scenario));
    
    // Record initial supply (should be 0)
    ts::next_tx(&mut scenario, user);
    let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
    let initial_supply = coin::total_supply(&cap);
    ts::return_shared(cap);
    
    let mint_amount = 500_000_000; // 5 RDX
    
    // Mint tokens
    ts::next_tx(&mut scenario, user);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, user, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };
    
    // Verify supply increased by the minted amount
    ts::next_tx(&mut scenario, user);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        let new_supply = coin::total_supply(&cap);
        assert!(new_supply == initial_supply + mint_amount, 6);
        ts::return_shared(cap);
        
        // Clean up the minted coin
        let minted_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        ts::return_to_sender(&scenario, minted_coin);
    };

    ts::end(scenario);
}
