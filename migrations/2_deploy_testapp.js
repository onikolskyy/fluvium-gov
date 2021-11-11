const TestApp = artifacts.require('TestApp');

module.exports = function(deployer,network) {

    if(network === "ganache"){
        return;
    }

    deployer.deploy(TestApp,
        "Governance",
        "gvx",
         "" ,                                           // owner
        "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9", // host
        "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8",  // cfa
        "0x95697ec24439E3Eb7ba588c7B279b9B369236941"  // token
        )
}