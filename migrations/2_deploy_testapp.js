const TestApp = artifacts.require('TestApp');

module.exports = async function(deployer,network) {
  console.log(">>> deploying TestApp to ", network)
    if(network === "ganache"){
        return;
    }
    await deployer.deploy(TestApp,
        "FluviumGovNFT",
        "FLGNFT",
        process.env.ADMIN ,                           // owner
        process.env.SUPERFLUID_HOST,                  // host
        process.env.CFA,                              // cfa
        process.env.SUPERFLUID_TOKEN                 // token
    )
    console.log("app deployed on: ",TestApp.address)
}