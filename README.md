# fluvium-gov :globe_with_meridians: :flying_saucer:
*Framework for DAOs allowing voting and distributing funds built with superfluid streams*


This is the counterpart to https://github.com/superfluid-finance/protocol-monorepo/tree/dao-global-examples/examples/dao-budgeting-nft:
The incoming flows are distributed to external objectives and the DAO issues NFTs which give their owner the permission to control the outgoing flows.

The voting mechanism is based on a simple uniform distribution:

Each Voter has 100 Votes and can assign those to objectives. The funds flow is scaled based on the total vote count given to each objective.

The process can be seen as a form of ***conviction voting***: The opinion of voters is evaluated continuosely over time.

Together with budgeting NFTs this contract can be used as a holistic framework for DAO governement. 

An explanation video: https://www.youtube.com/watch?v=G6NTRRKp6LM&t=4s

______________________________________________
**Build from source**
- hit `npm install` to install dependencies
- open a local Ganache instance eg by running `ganache-cli`
- To deploy the superfluid framework locally, run `DISABLE_NATIVE_TRUFFLE=true NEW_TEST_RESOLVER=1 truffle --network ganache exec "node_modules/@superfluid-finance/ethereum-contracts/scripts/deploy-test-environment.js" > log.txt
`
- Copy the addresses for `fDai` and the `Resolver` from `log.txt` to a `.dotenv` file. (Hint: The resolver address should appear in the last line of `log.txt`)
- To run tests, hit truffle `test --network ganache` 

***Dependencies***
- truffle
- ganache-cli
_____________________________________________

More info on superfluid:
https://docs.superfluid.finance/superfluid/

***Built for the DAO Global Hackathon ***
______________________________________________

TODOs:

1. implement NFT issuing
2. provide more tests
4. optimize memory usage
5. integrate the budgeting functionality
6. build a frontend
7. deploy on Goerli
