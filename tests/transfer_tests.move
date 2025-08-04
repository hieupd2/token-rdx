#[test_only]
module token_rdx::transfer_tests;

// Import test framework for blockchain simulation
use sui::test_scenario::{Self as ts};
// Import coin functionality
use sui::coin::{Self, Coin, TreasuryCap};
// Import our token functions
use token_rdx::rdx::{RDX, mint, transfer, test_init};

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests for transfer function
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fun test_transfer_basic() {
    // Test basic transfer of entire coin from one user to another
    let alice = @0x1;  // Original owner
    let bob = @0x2;    // Transfer recipient
    
    let mut scenario = ts::begin(alice);
    
    // Initialize contract
    test_init(ts::ctx(&mut scenario));
    
    let mint_amount = 100_000_000; // 1 RDX
    
    // Alice mints tokens for herself
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers her entire coin to Bob
    ts::next_tx(&mut scenario, alice);
    {
        // Alice takes her coin
        let coin_to_transfer = ts::take_from_sender<Coin<RDX>>(&scenario);
        // Verify Alice has the right amount before transferring
        assert!(coin::value(&coin_to_transfer) == mint_amount, 0);
        // Transfer the entire coin to Bob
        transfer(coin_to_transfer, bob);
    };

    // Verify Bob received the coin
    ts::next_tx(&mut scenario, bob);
    {
        let received_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        // Check Bob received the correct amount
        assert!(coin::value(&received_coin) == mint_amount, 1);
        ts::return_to_sender(&scenario, received_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_zero_value_coin() {
    // Test transferring a coin with zero value
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    // Mint a zero-value coin to Alice
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, 0, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers the zero-value coin to Bob
    ts::next_tx(&mut scenario, alice);
    {
        let zero_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&zero_coin) == 0, 2);
        transfer(zero_coin, bob);
    };

    // Verify Bob received the zero-value coin
    ts::next_tx(&mut scenario, bob);
    {
        let received_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&received_coin) == 0, 3);
        ts::return_to_sender(&scenario, received_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_large_amount() {
    // Test transferring a very large amount
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let large_amount = 999_999_999_000_000_000; // Very large amount
    
    // Mint large amount to Alice
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, large_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers to Bob
    ts::next_tx(&mut scenario, alice);
    {
        let large_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&large_coin) == large_amount, 4);
        transfer(large_coin, bob);
    };

    // Verify Bob received the large amount
    ts::next_tx(&mut scenario, bob);
    {
        let received_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&received_coin) == large_amount, 5);
        ts::return_to_sender(&scenario, received_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_chain() {
    // Test a chain of transfers: Alice -> Bob -> Carol -> Dave
    let alice = @0x1;
    let bob = @0x2;
    let carol = @0x3;
    let dave = @0x4;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let transfer_amount = 250_000_000; // 2.5 RDX
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, transfer_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice -> Bob
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer(coin, bob);
    };

    // Bob -> Carol
    ts::next_tx(&mut scenario, bob);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin) == transfer_amount, 6);
        transfer(coin, carol);
    };

    // Carol -> Dave
    ts::next_tx(&mut scenario, carol);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin) == transfer_amount, 7);
        transfer(coin, dave);
    };

    // Verify Dave has the final coin
    ts::next_tx(&mut scenario, dave);
    {
        let final_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&final_coin) == transfer_amount, 8);
        ts::return_to_sender(&scenario, final_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_multiple_coins() {
    // Test transferring multiple separate coins from one user to another
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let first_amount = 100_000_000;  // 1 RDX
    let second_amount = 200_000_000; // 2 RDX
    let third_amount = 300_000_000;  // 3 RDX
    
    // Alice mints three separate coins
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, first_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };
    
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, second_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };
    
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, third_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers all three coins to Bob one by one
    ts::next_tx(&mut scenario, alice);
    {
        let coin1 = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer(coin1, bob);
    };
    
    ts::next_tx(&mut scenario, alice);
    {
        let coin2 = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer(coin2, bob);
    };
    
    ts::next_tx(&mut scenario, alice);
    {
        let coin3 = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer(coin3, bob);
    };

    // Verify Bob received all three coins
    ts::next_tx(&mut scenario, bob);
    {
        // Bob should have three separate coin objects
        let coin1 = ts::take_from_sender<Coin<RDX>>(&scenario);
        let coin2 = ts::take_from_sender<Coin<RDX>>(&scenario);
        let coin3 = ts::take_from_sender<Coin<RDX>>(&scenario);
        
        // Calculate total value received
        let total_received = coin::value(&coin1) + coin::value(&coin2) + coin::value(&coin3);
        let expected_total = first_amount + second_amount + third_amount;
        
        assert!(total_received == expected_total, 9);
        
        // Return coins to Bob
        ts::return_to_sender(&scenario, coin1);
        ts::return_to_sender(&scenario, coin2);
        ts::return_to_sender(&scenario, coin3);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_self() {
    // Test transferring a coin to oneself (edge case)
    let alice = @0x1;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let amount = 150_000_000; // 1.5 RDX
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers to herself
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin) == amount, 10);
        transfer(coin, alice); // Transfer to self
    };

    // Verify Alice still has the coin
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin) == amount, 11);
        ts::return_to_sender(&scenario, coin);
    };

    ts::end(scenario);
}
