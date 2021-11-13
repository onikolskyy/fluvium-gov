const TestApp = artifacts.require('TestApp');
const TestAppABI  = TestApp.abi;
const Web3 = require("web3");

const _sender = '0x607b8B859926446e339df08073eb47c740c9E17D'

function parseColonArgs(argv) {
    const argIndex = argv.indexOf(":");
    if (argIndex < 0) {
        throw new Error("No colon arguments provided");
    }
    const args = argv.slice(argIndex + 1);
    console.log("Colon arguments", args);
    return args;
}


module.exports = async function(cb, argv) {

    const web3 = new Web3(new Web3.providers.WebsocketProvider(process.env.WEBSOCKET_PROVIDER));
    const app = await new web3.eth.Contract(TestAppABI, TestApp.address);

    const args = parseColonArgs(argv || process.argv);

    if (args.length !== 2) {
        console.log("Wrong number of arguments");
        cb()
    }

    const _receiver = args.pop()
    const _sender = args.pop();

    const txData = (await app.methods.issueNFT(_receiver)).encodeABI()
    const nonce = await web3.eth.getTransactionCount(_sender, 'latest'); // nonce starts counting from 0

    let tx = {
        'to': TestApp.address,
        'gas': 3000000,
        'nonce': nonce,
        'data': txData
    }

  let signedTx = await web3.eth.accounts.signTransaction(tx, process.env.SECRET);

  await web3.eth.sendSignedTransaction(signedTx.rawTransaction, function(error, hash) {
    if (!error) {
        console.log("🎉 The hash of your transaction is: ", hash);
    } else {
        console.log("❗Something went wrong while submitting your transaction:", error)
    }
   });



}