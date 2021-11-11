const TestNFT = artifacts.require('TradeableCashflow');

module.exports = function(deployer,network) {
    if(network === "ganache"){
        return;
    }


    deployer.deploy(TestNFT,
        '0x5b832617675dFa306d2d1b5b0e07E7b4e6FFbBB4', // owner
        'TEST',
        'TTT',
        "0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9",
        "0xEd6BcbF6907D4feEEe8a8875543249bEa9D308E8",
        "0x95697ec24439E3Eb7ba588c7B279b9B369236941"
        )
}
