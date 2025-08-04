#[test_only]
module token_rdx::transfer_amount_tests;

// Import test framework for blockchain simulation
use sui::test_scenario::{Self as ts};
// Import coin functionality for handling partial amounts
use sui::coin::{Self, Coin, TreasuryCap};
// Import our token functions and error constants
use token_rdx::rdx::{RDX, mint, transfer_amount, test_init, E_AMOUNT_ZERO, E_INSUFFICIENT};

// ─────────────────────────────────────────────────────────────────────────────
// Unit tests for transfer_amount function (partial transfers)
// ─────────────────────────────────────────────────────────────────────────────

#[test]
fun test_transfer_amount_partial() {
    // Test transferring a partial amount while keeping remainder
    let alice = @0x1;  // Original owner who keeps remainder
    let bob = @0x2;    // Recipient of partial amount
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let total_amount = 100_000_000;   // 1 RDX total
    let transfer_amount = 30_000_000; // 0.3 RDX to transfer
    let expected_remainder = total_amount - transfer_amount; // 0.7 RDX remainder
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, total_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers partial amount to Bob (function returns remainder to alice)
    ts::next_tx(&mut scenario, alice);
    {
        let original_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        // Verify original amount before transfer
        assert!(coin::value(&original_coin) == total_amount, 0);
        // Transfer partial amount to Bob (remainder will be sent back to Alice)
        transfer_amount(original_coin, transfer_amount, bob, ts::ctx(&mut scenario));
    };

    // Verify Alice received the remainder
    ts::next_tx(&mut scenario, alice);
    {
        let remainder_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&remainder_coin) == expected_remainder, 1);
        ts::return_to_sender(&scenario, remainder_coin);
    };

    // Verify Bob received the partial amount
    ts::next_tx(&mut scenario, bob);
    {
        let transferred_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&transferred_coin) == transfer_amount, 2);
        ts::return_to_sender(&scenario, transferred_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_amount_entire_coin() {
    // Test transferring the entire coin amount (should behave like transfer)
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let total_amount = 50_000_000; // 0.5 RDX
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, total_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers entire amount to Bob
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        // Transfer the entire amount (no remainder will be returned)
        transfer_amount(coin, total_amount, bob, ts::ctx(&mut scenario));
    };

    // Verify Bob received the entire amount
    ts::next_tx(&mut scenario, bob);
    {
        let received_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&received_coin) == total_amount, 4);
        ts::return_to_sender(&scenario, received_coin);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = E_AMOUNT_ZERO)] // E_AMOUNT_ZERO
fun test_transfer_amount_zero() {
    // Test transferring zero amount (should fail with E_AMOUNT_ZERO)
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let original_amount = 100_000_000; // 1 RDX
    let transfer_amount = 0;            // Transfer nothing (should fail)
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, original_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice tries to "transfer" zero amount to Bob (this should fail)
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer_amount(coin, transfer_amount, bob, ts::ctx(&mut scenario));
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_amount_multiple_splits() {
    // Test splitting one coin into multiple partial transfers
    let alice = @0x1;
    let bob = @0x2;
    let carol = @0x3;
    let dave = @0x4;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let total_amount = 1_000_000_000;  // 10 RDX
    let first_transfer = 100_000_000;  // 1 RDX to Bob
    let second_transfer = 250_000_000; // 2.5 RDX to Carol
    let third_transfer = 150_000_000;  // 1.5 RDX to Dave
    let expected_remainder = total_amount - first_transfer - second_transfer - third_transfer; // 5 RDX left
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, total_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice makes three partial transfers
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        
        // First transfer to Bob
        transfer_amount(coin, first_transfer, bob, ts::ctx(&mut scenario));
    };

    // Alice receives remainder and transfers to Carol
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin) == total_amount - first_transfer, 7);
        
        // Second transfer to Carol
        transfer_amount(coin, second_transfer, carol, ts::ctx(&mut scenario));
    };

    // Alice receives remainder and transfers to Dave
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&coin) == total_amount - first_transfer - second_transfer, 8);
        
        // Third transfer to Dave
        transfer_amount(coin, third_transfer, dave, ts::ctx(&mut scenario));
    };

    // Alice should have the final remainder
    ts::next_tx(&mut scenario, alice);
    {
        let final_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&final_coin) == expected_remainder, 9);
        ts::return_to_sender(&scenario, final_coin);
    };

    // Verify Bob received correct amount
    ts::next_tx(&mut scenario, bob);
    {
        let bob_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&bob_coin) == first_transfer, 10);
        ts::return_to_sender(&scenario, bob_coin);
    };

    // Verify Carol received correct amount
    ts::next_tx(&mut scenario, carol);
    {
        let carol_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&carol_coin) == second_transfer, 11);
        ts::return_to_sender(&scenario, carol_coin);
    };

    // Verify Dave received correct amount
    ts::next_tx(&mut scenario, dave);
    {
        let dave_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&dave_coin) == third_transfer, 12);
        ts::return_to_sender(&scenario, dave_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_amount_precise_calculations() {
    // Test precise decimal calculations (testing edge cases with small amounts)
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let total_amount = 1_000_001;      // 0.01000001 RDX (very precise)
    let transfer_amount = 500_000;     // 0.005 RDX (half + 1 unit)
    let expected_remainder = 500_001;  // 0.00500001 RDX
    
    // Alice mints precise amount
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, total_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers precise amount
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer_amount(coin, transfer_amount, bob, ts::ctx(&mut scenario));
    };

    // Verify Alice received precise remainder
    ts::next_tx(&mut scenario, alice);
    {
        let remainder_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&remainder_coin) == expected_remainder, 13);
        ts::return_to_sender(&scenario, remainder_coin);
    };

    // Verify Bob received precise amount
    ts::next_tx(&mut scenario, bob);
    {
        let received_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&received_coin) == transfer_amount, 14);
        ts::return_to_sender(&scenario, received_coin);
    };

    ts::end(scenario);
}

#[test]
fun test_transfer_amount_large_numbers() {
    // Test transfer_amount with very large numbers
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let total_amount = 999_999_999_000_000_000;    // Very large total
    let transfer_amount = 123_456_789_000_000_000; // Large partial transfer
    let expected_remainder = total_amount - transfer_amount;
    
    // Alice mints large amount
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, total_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice transfers large partial amount
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer_amount(coin, transfer_amount, bob, ts::ctx(&mut scenario));
    };

    // Verify Alice received large remainder
    ts::next_tx(&mut scenario, alice);
    {
        let remainder_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&remainder_coin) == expected_remainder, 15);
        ts::return_to_sender(&scenario, remainder_coin);
    };

    // Verify Bob received large amount
    ts::next_tx(&mut scenario, bob);
    {
        let received_coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        assert!(coin::value(&received_coin) == transfer_amount, 16);
        ts::return_to_sender(&scenario, received_coin);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = E_INSUFFICIENT)]
fun test_transfer_amount_insufficient() {
    // Test transferring more than available amount (should fail with E_INSUFFICIENT)
    let alice = @0x1;
    let bob = @0x2;
    
    let mut scenario = ts::begin(alice);
    
    test_init(ts::ctx(&mut scenario));
    
    let mint_amount = 50_000_000;      // 0.5 RDX
    let transfer_amount = 100_000_000; // Try to transfer 1 RDX (more than available)
    
    // Alice mints tokens
    ts::next_tx(&mut scenario, alice);
    {
        let mut cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        mint(&mut cap, mint_amount, alice, ts::ctx(&mut scenario));
        ts::return_shared(cap);
    };

    // Alice tries to transfer more than she has (this should fail)
    ts::next_tx(&mut scenario, alice);
    {
        let coin = ts::take_from_sender<Coin<RDX>>(&scenario);
        transfer_amount(coin, transfer_amount, bob, ts::ctx(&mut scenario));
    };

    ts::end(scenario);
}
