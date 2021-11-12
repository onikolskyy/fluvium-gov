# fluvium-gov
*Framework for DAOs allowing voting and distributing funds built with superfluid streams*


This is a counterpart to https://github.com/superfluid-finance/protocol-monorepo/tree/dao-global-examples/examples/dao-budgeting-nft:
The incoming flows are distributed among given objectives and the DAO issues NFTs which give their owner the permission to control the outgoing flows.

The voting mechanism is based on a simple uniform distribution:

Each owner has 100 Votes and can assign those to objectives. The funds flow is scaled based on the total vote count given to each objective.

The process can be seen as a form of ***conviction voting***: The opinion of voters is evaluated continuosely over time.

Together with budgeting NFTs this contract can be used as a framework for a holistic DAO governement. 

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
