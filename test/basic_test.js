const { web3tx, toWad } = require("@decentral.ee/web3-helpers");
const BN = web3.utils.BN;

const SuperfluidSDK = require("@superfluid-finance/js-sdk");
const Test = artifacts.require("TestApp")

process.env.NEW_TEST_RESOLVER = 1;
//process.env.ENABLE_APP_WHITELISTING = 0;

const errorHandler = err => {
    if (err) throw err;
};

async function flowExists(sf,from,to) {
        var value =
            (
                await sf.agreements.cfa.getFlow.call(
                    daix.address,
                    from,
                    to
                )
            )[1].toString();
        // console.log("flow of: " + users[who] + " exists? " + value);
        return value;
}


 async function sendDai(sf,from, to, amount,token) {
    return await sf.host.callAgreement(
        sf.agreements.cfa.address,
        sf.agreements.cfa.contract.methods
            .createFlow(
                token.address,
                to.toString(),
                amount.toString(),
                "0x"
            )
            .encodeABI(),
        "0x", // user data
        {
            from: from.toString()
        }
    );
}

  async function printRealtimeBalance(label, account, token) {
        const b = await token.realtimeBalanceOfNow.call(account);
        console.log(
            `${label} realtime balance`,
            b.availableBalance.toString(),
            b.deposit.toString(),
            b.owedDeposit.toString()
        );
        return b;
    }

contract("FluviumGov-Basic", accounts => {

    let sf;

    accounts = accounts.slice(0, 8);
    const [admin, bob, carol, dan, optionA, optionB, optionC] = accounts;

    console.log(">>admin", admin)
    console.log(">>bob", bob)
    console.log(">>optionB", optionB)

    before(async function(){
         sf = new SuperfluidSDK.Framework({web3,version: "test",tokens: ['fDAI']})
         await sf.initialize();
    })

    beforeEach(async function() {
       dai = await sf.contracts.TestToken.at(process.env.TEST_FDAI_ADDRESS);

        for (let i = 0; i < accounts.length; ++i) {
            await web3tx(dai.mint, `Account ${i} mints many dai`)(
                accounts[i],
                toWad(10000000),
                {from: accounts[i]}
            );
        }

        daix = sf.tokens.fDAIx;


        app = await Test.new(
            "GovernanceNFT",
            "GOVx",
            admin,
            sf.host.address,
            sf.agreements.cfa.address,
            daix.address
        );

        for (let i = 0; i < accounts.length-3; ++i) {
            await web3tx(
                dai.approve,
                `Account ${i} approves daix`
            )(daix.address, toWad(1000), {from: accounts[i]});

            await daix.upgrade((toWad(1000)).toString(), {
                from: accounts[i]
            });
        }

             // dan gives app a dollar so it won't break
            await daix.transfer(app.address, (toWad(1000)).toString(), { from: dan });

    })

    it("#1: basic",async ()=>{
/*
        // Admin creates a flow of global funds
        await sf.cfa.createFlow({
            superToken:daix.address,
            sender: admin,
            receiver: app.address,
            flowRate: String("385802469135802")
        });*/

        let res = await app.issueNFT(bob, {from:admin});
        let tokenId = res.logs[0].args.tokenId

        // There are two options which can be funded
        await app.makeProposal(optionA, {from:admin});
        await app.makeProposal(optionB, {from:admin});

        // Now the fellow DAOists have to vote!
        await app.reVote(tokenId,optionA, "5", {from: bob});
        await app.reVote(tokenId, optionB, "10", {from: bob});
        //
        //
        // carol provides more funding streams!
        await sf.cfa.createFlow({
            superToken:daix.address,
            sender: carol,
            receiver: app.address,
            flowRate: String("385802469135802")
        });


        console.log(await flowExists(sf, app.address, optionB))
        await app.reVote(tokenId, optionB, "20", {from: bob});
        console.log(await flowExists(sf, app.address, optionB))


        await sf.cfa.createFlow({
            superToken:daix.address,
            sender: carol,
            receiver: app.address,
        });

        console.log(await flowExists(sf, app.address, optionB))

    })

})