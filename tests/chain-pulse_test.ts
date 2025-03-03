import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures that transaction recording works with initialization",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
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
  name: "Ensures contract pause functionality works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-pulse",
        "toggle-contract-pause",
        [],
        deployer.address
      ),
      Tx.contractCall(
        "chain-pulse",
        "record-transaction",
        [types.uint(1000)],
        deployer.address
      )
    ]);

    block.receipts[0].result.expectOk().expectBool(true);
    block.receipts[1].result.expectErr(types.uint(104));
  }
});

Clarinet.test({
  name: "Ensures maximum transaction amount is enforced",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "chain-pulse",
        "record-transaction",
        [types.uint(1000000000001)],
        deployer.address
      )
    ]);

    block.receipts[0].result.expectErr(types.uint(101));
  }
});
