const { web3tx, toWad } = require("@decentral.ee/web3-helpers");

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
            )[1].toString() !== "0";
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

contract("RoleGovFlow", accounts => {

    let sf;

    accounts = accounts.slice(0, 7);
    const [admin, bob, carol, dan, optionA, optionB] = accounts;

    before(async function(){
         sf = new SuperfluidSDK.Framework({web3,version: "test",tokens: ['fDAI']})
         await sf.initialize();
    })

    beforeEach(async function() {
       dai = await sf.contracts.TestToken.at("0x59fA86f45767190Bcb925538Add2804d50348a9F");

        for (let i = 0; i < accounts.length; ++i) {
            await web3tx(dai.mint, `Account ${i} mints many dai`)(
                accounts[i],
                toWad(10000000),
                {from: accounts[i]}
            );
        }

        daix = sf.tokens.fDAIx;

        app = await web3tx(Test.new, "Deploy LotterySuperApp")(
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

            // dan gives app a dollar so it won't break
            await daix.transfer(app.address, (1 * 1e18).toString(), { from: dan });
        }
    })

    it("#1",async ()=>{

        // Admin creates a flow of global funds
        await sf.cfa.createFlow({
            superToken:daix.address,
            sender: admin,
            receiver: app.address,
            flowRate: String("385802469135802")
        });

        // There are two options which can be funded
        await app.addObjective(optionA);
        await app.addObjective(optionB);

        // Now the fellow DAOists have to vote!
        await app.reVote(optionA, "10", {from: bob});
        await app.reVote(optionB, "90", {from: bob});
        //app.reVoteTest().on('data', event => console.log(event))


        // carol provides more funding streams!
        await sf.cfa.createFlow({
            superToken:daix.address,
            sender: carol,
            receiver: app.address,
            flowRate: String("385802469135802")
        });




    })


})