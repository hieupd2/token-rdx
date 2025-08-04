#[test_only]
module token_rdx::init_tests;

use sui::test_scenario::{Self as ts};
use sui::coin::{Self, TreasuryCap, CoinMetadata};
use std::ascii;
use token_rdx::rdx::{RDX, test_init_coverage};

// Test the init function to improve coverage
#[test]
fun test_init_function() {
    let admin = @0x1;
    
    let mut scenario = ts::begin(admin);
    
    // Call the actual init function to increase coverage
    ts::next_tx(&mut scenario, admin);
    {
        // This will execute the init function and improve coverage
        test_init_coverage(ts::ctx(&mut scenario));
    };
    
    // Verify TreasuryCap was created and shared
    ts::next_tx(&mut scenario, admin);
    {
        let cap = ts::take_shared<TreasuryCap<RDX>>(&scenario);
        
        // Verify the treasury cap exists and has correct type
        assert!(coin::total_supply(&cap) == 0, 0);
        
        ts::return_shared(cap);
    };
    
    // Verify CoinMetadata was created and frozen
    ts::next_tx(&mut scenario, admin);
    {
        // Take the frozen metadata object
        let metadata = ts::take_immutable<CoinMetadata<RDX>>(&scenario);
        
        // Just verify basic properties (avoid string comparison issues)
        assert!(coin::get_decimals(&metadata) == 8, 1);
        // Symbol is ASCII string
        assert!(coin::get_symbol(&metadata) == ascii::string(b"RDX"), 2);
        
        ts::return_immutable(metadata);
    };
    
    ts::end(scenario);
}
