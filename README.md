# MultiCaller

A modern approach to Solidity transaction/call batching.

⚠️ **STOP:** This is a highly experimental repository. I literally hacked the contract together in 15 minutes and there are no tests yet (I know, I know!).

## Motivation

There have been a lot of implementations for batching in the past. This repo combines both `multicall` and `multisend` with modern syntax niceties like `abicoder v2` and custom errors.

There is also both "fire and forget" and "fail all if one fails" variations of all methods.

## Usage

The hardest part is to encode the calldata for each call separately.

With Solidity this can be done with [`abi.encodeWithSignature`](https://docs.soliditylang.org/en/v0.8.17/cheatsheet.html?highlight=encodewithsignature#global-variables) and its siblings `abi.encodeCall` and `abi.encodeWithSelector`.

Other tools will most likely have an equivalent, like `ethers.js` utility [`Interface#encodeFunctionData`](https://docs.ethers.org/v5/api/utils/abi/interface).

Let's say you want to transfer Dai to multiple parties at once:

```solidity
address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

MultiCaller.Call[] memory calls = new MultiCaller.Call[](3);

calls[0].target = dai;
calls[0].data = abi.encodeWithSignature(
    'transferFrom(address from, address to, uint amount)',
    0x1234...,
    0x2345...,
    100_000000000000000000 // 100 Dai
)

calls[1].target = dai;
calls[1].data = abi.encodeWithSignature(
    'transferFrom(address from, address to, uint amount)',
    0x1234...,
    0x1337...,
    90_000000000000000000 // 90 Dai
)

calls[2].target = dai;
calls[2].data = abi.encodeWithSignature(
    'transferFrom(address from, address to, uint amount)',
    0x1234...,
    0x2338...,
    70_000000000000000000 // 70 Dai
)
```

### Fire and forget

If you don't care about the result of the transaction, you can use the "fire and forget" `multiSend`:

```solidity
multiCaller.multiSend(calls);
```

If any of the Dai transfers fail, it will simply be ignored. Notice that the way ERC-20 approvals work, the `from` contract must have approved the `multiCaller` instance to spend Dai in its behalf.

ℹ️ The `MultiCaller` contract has no storage, which means it is safe to be used as a target for `delegatecall`.

### Fail all if one fails

If you must make sure that all transactions from the batch are executed, you can use `atomicMultisend`:

```solidity
multiCaller.atomicMultiSend(calls);
```

If any of the Dai transfers fail, it will revert all transfers.

### Payable transactions

If you need to send ETH to call a `payable` method you need to use the `PayableCall` struct to provide one extra param: the `value`.

```solidity
MultiCaller.PayableCall[] memory calls = new MultiCaller.PayableCall[](2);

calls[0].target = 0x9876...;
calls[0].data = abi.encodeWithSignature(
    'somethingPayable(address)',
    0x1234...
)
calls[0].value = 0.1 ether;

calls[1].target = 0x9876...;
calls[1].data = abi.encodeWithSignature(
    'somethingPayable(address)',
    0x1337...
)
calls[1].value = 0.3 ether;
```

Then you can use the overloaded `multiSend` and `atomicMultisend` methods. Don't forget to provide enough ETH in the call to cover for the total amount:

```solidity
// 0.1 ether + 0.3 ether = 0.4 ether
multiCaller.atomicMultisend{value: 0.4 ether}(calls);
```

### Read-only calls

Suppose you need to read the Dai balance of multiple accounts at once, but you are really short on RPC calls to make. You can optimize it with `MultiCaller`.

Prepare the call:

```solidity
address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

MultiCaller.Call[] memory calls = new MultiCaller.Call[](3);

calls[0].target = dai;
calls[0].data = abi.encodeWithSignature(
    'balanceOf(address)',
    0x1234...
)

calls[1].target = dai;
calls[1].data = abi.encodeWithSignature(
    'balanceOf(address)',
    0x1337...
)

calls[2].target = dai;
calls[2].data = abi.encodeWithSignature(
    'balanceOf(address)',
    0x2338...
)
```

Then use the `multiCall` method:

```solidity
multiCaller.multiCall(calls);
```

If your calls might fail, you probably want to use the `atomicMultiCall` variant to fail the entire call if one of them fails.
