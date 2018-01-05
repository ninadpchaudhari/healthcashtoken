
## Health Cash :: ERC20 Token

This is set of contracts to create, issue and sell an ERC 20 compliant token. These contracts support: 

* Airdrops
* whitelists sale
* Token sales 
* Presale
* Burning tokens
* Freezing tokens


## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. 

### Prerequisites

To run this locally you will need the [Truffle framework](http://truffleframework.com/), node.js, npm, and a local development ethereum node


### Installing

Install truffle

```

$ npm install -g truffle

```

Once you have cloned the project, from inside the project directory you'll need to run npm install to get the 
testing libraries. 

```

$ npm install

```

Start up your ethereum node then compile and deploy your contracts. You'll need two unlocked accounts on your
ethereum client to be able to run the token transfer tests successfully.

```

$ truffle compile
$ truffle migrate

```


## Running the tests

Once the contracts are deployed to your development ethereum node you can run the test like this. 

```

$ truffle test

```

### Test Overview



Major dependencies:

* [Truffle](https://github.com/trufflesuite/truffle)

Contributors:

* **Lucas Hendren** - [lhendre](https://github.com/lhendre)
* **David Akers** - [davidmichaelakers](https://github.com/davidmichaelakers)

## License

[Apache License 2.0](https://github.com/Health-Nexus/drs/blob/master/LICENSE)

## Acknowledgments

* [SimplyVital Health](https://www.simplyvitalhealth.com/)
* [OpenZeppelin](https://github.com/OpenZeppelin)
* [TokenMarket](https://github.com/TokenMarketNet/ico/tree/master/contracts)
