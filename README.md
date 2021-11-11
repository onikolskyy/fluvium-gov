# fluvium-gov
*Framework for DAOs allowing voting and distributing funds built with superfluid streams*


This is a counterpart to https://github.com/superfluid-finance/protocol-monorepo/tree/dao-global-examples/examples/dao-budgeting-nft:
the DAO issues NFTs which give their owner the permission to control the funds distribution of the DAO. 

The voting mechanism is based on a simple uniform distribution:

Each owner has 100 Votes and can assign those to objectives. The funds flow is scaled based on the total vote count given to each objective.

The process can be seen as a form of ***conviction voting***: The opinion of voters is evaluated continuosely over time.

_____________________________________________

More info on superfluid:
https://docs.superfluid.finance/superfluid/
