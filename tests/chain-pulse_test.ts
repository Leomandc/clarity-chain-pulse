import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures that transaction recording works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-pulse",
        "record-transaction",
        [types.uint(1000)],
        deployer.address
      )
    ]);

    block.receipts[0].result.expectOk().expectBool(true);
    
    let dailyStats = chain.callReadOnlyFn(
      "chain-pulse",
      "get-daily-stats",
      [types.uint(0)],
      deployer.address
    );
    
    dailyStats.result.expectSome();
  }
});

Clarinet.test({
  name: "Ensures active address recording works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-pulse",
        "record-active-address",
        [types.principal(deployer.address)],
        deployer.address
      )
    ]);

    block.receipts[0].result.expectOk().expectBool(true);
    
    let addressActivity = chain.callReadOnlyFn(
      "chain-pulse",
      "get-address-last-active",
      [types.principal(deployer.address)],
      deployer.address
    );
    
    addressActivity.result.expectSome();
  }
});
