/*
/// Module: token_RDX
module token_RDX::token_RDX;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions


module token_rdx::rdx;

use sui::coin::{Self, TreasuryCap, Coin};
use sui::url;

#[error]
const E_AMOUNT_ZERO: vector<u8> = b"Zero Amount";

#[error]
const E_INSUFFICIENT: vector<u8> = b"Insufficient Amount";

public struct RDX has drop {}

fun init(witness: RDX, ctx: &mut TxContext) {
        let icon_url = url::new_unsafe_from_bytes(
        b"https://framerusercontent.com/images/0KKocValgAmB9XHzcFI6tALxGGQ.jpg"
    );
    let decimals: u8 = 8;

    // Tạo currency
    let (cap, metadata) = coin::create_currency(
        witness,
        decimals,
        b"RDX",
        b"RDX ON SUI",
        b"Unlimited-mint RDX token",
        option::some(icon_url),
        ctx,
    );

    // share public cap object to allow everyone to mint
    transfer::public_share_object(cap);

    // freeze metadata
    transfer::public_freeze_object(metadata);
}

// Note: everyone can mint
public entry fun mint(    
    treasury_cap: &mut TreasuryCap<RDX>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    let coin = coin::mint(treasury_cap, amount, ctx);
    transfer::public_transfer(coin, recipient);
}

public entry fun burn(cap: &mut TreasuryCap<RDX>, c: Coin<RDX>) {
    coin::burn<RDX>(cap, c);
}

public entry fun transfer(c: Coin<RDX>, recipient: address) {
    transfer::public_transfer(c, recipient);
}

public entry fun burn_amount(
    cap: &mut TreasuryCap<RDX>,
    mut c: Coin<RDX>,
    amount: u64,
    ctx: &mut TxContext
) {
    assert!(amount > 0, E_AMOUNT_ZERO);

    let bal = coin::value<RDX>(&c);
    assert!(amount <= bal, E_INSUFFICIENT);

    if (amount == bal) {
        coin::burn<RDX>(cap, c);
        return
    };

    let to_burn = coin::split<RDX>(&mut c, amount, ctx);
    coin::burn<RDX>(cap, to_burn);
    // Trả phần còn lại về ví người gọi
    transfer::public_transfer(c, tx_context::sender(ctx));
}

public entry fun transfer_amount(
    mut c: Coin<RDX>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {

    assert!(amount > 0, E_AMOUNT_ZERO);

    let bal = coin::value<RDX>(&c);
    assert!(amount <= bal, E_INSUFFICIENT);

    if (amount == bal) {
        transfer::public_transfer(c, recipient);
        return
    };

    let to_send = coin::split<RDX>(&mut c, amount, ctx);
    transfer::public_transfer(to_send, recipient);
    // Trả phần còn lại về ví người gọi
    transfer::public_transfer(c, tx_context::sender(ctx));
}

#[test_only]
/// Test-only function to initialize the contract for testing
public fun test_init(ctx: &mut TxContext) {
    init(RDX {}, ctx)
}

#[test_only]
/// Test-only function to call init directly for coverage testing
public fun test_init_coverage(ctx: &mut TxContext) {
    init(RDX {}, ctx)
}