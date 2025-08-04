
module token_rdx::staking;

use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::event;
use sui::linked_table::{Self, LinkedTable};

const E_INVALID_AMOUNT: u64 = 0;
const E_INSUFFICIENT_AMOUNT: u64 = 1;

public struct AdminCap has key {
    id: UID,
}

public struct LiquidPool<phantom T> has key {
    id: UID,
    balance: Balance<T>,
    staked_amounts: LinkedTable<address, u64>
}

public struct PoolAddedEvent has copy, drop {
    pool_id: ID,
    creator: address
}

public struct DepositedEvent has copy, drop {
    pool_id: ID,
    user: address,
    amount: u64
}

public struct WithdrawnEvent has copy, drop {
    pool_id: ID,
    user: address,
    amount: u64
}

fun init(ctx: &mut TxContext) {
    // transfer the admin cap to the creator
    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::transfer(admin_cap, ctx.sender());
}

entry fun create_pool<T>(ctx: &mut TxContext) {
    let pool = LiquidPool<T> {
        id: object::new(ctx),
        balance: balance::zero<T>(),
        staked_amounts: linked_table::new(ctx)
    };

    let pool_id = object::id(&pool);
    transfer::share_object(pool);

    event::emit(PoolAddedEvent { pool_id: pool_id, creator: ctx.sender() });
}

entry fun deposit<T>(
    pool: &mut LiquidPool<T>,
    coin: Coin<T>,
    ctx: &TxContext
) {
    let new_amount = coin::value(&coin);
    assert!(new_amount > 0, E_INVALID_AMOUNT);

    // update amount in pool
    if (linked_table::contains(&pool.staked_amounts, ctx.sender())) {
        // return biến tham chiếu mutable staked_amounts ô nhớ chứa giá trị amount của người dùng
        // staked_amounts là một biến tham chiếu, không chứa giá trị trực tiếp
        let staked_amount = linked_table::borrow_mut(&mut pool.staked_amounts, ctx.sender());
        // Cập nhật số lượng đã stake sử dụng toán tử dereference *
        *staked_amount = *staked_amount + new_amount;
    } else {
        linked_table::push_back(&mut pool.staked_amounts, ctx.sender(), new_amount);
    };

    // Join the coin's balance into the pool's balance
    let balance = coin::into_balance(coin);
    balance::join(&mut pool.balance, balance);

    // Emit event
    event::emit(DepositedEvent { pool_id: object::id(pool), user: ctx.sender(), amount: new_amount });
}


entry fun withdraw<T>(pool: &mut LiquidPool<T>, amount: u64, ctx: &mut TxContext) {
    assert!(amount > 0, E_INVALID_AMOUNT);

    // Check if the user has enough staked amount
    let staked_amount = linked_table::borrow_mut(&mut pool.staked_amounts, ctx.sender());
    assert!(*staked_amount >= amount, E_INSUFFICIENT_AMOUNT);

    // Update the staked amount
    *staked_amount = *staked_amount - amount;

    // Create a coin with the withdrawn amount and transfer it to the user
    let coin = coin::from_balance(balance::split(&mut pool.balance, amount), ctx);
    transfer::public_transfer(coin, ctx.sender());

    // Emit event
    event::emit(WithdrawnEvent { pool_id: object::id(pool), user: ctx.sender(), amount });
}