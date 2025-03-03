import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous test cases remain unchanged...]

Clarinet.test({
  name: "Ensures daily volume limits are enforced",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-pulse",
        "record-transaction",
        [types.uint(10000000000001)],
        deployer.address
      )
    ]);

    block.receipts[0].result.expectErr(types.uint(105));
  }
});

// [Additional test cases for new functionality...]
