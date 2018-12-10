
# SIA Flight Insurance Smart Contract

This project is a decentralized flight insurance application. It allows anyone to pool money together, in the form of ether, and retrieve an insured sum if a flight is cancelled or delayed. The project revolves around the Singapore Airlines API, and comprises of a VueJS front-end and a Ethereum Smart Contract back-end. All personal data is stored either on the client side or on the smart contract, never server-side. 

## Private Testnet setup

### Ganache
Firstly, download Ganache, a private Ethereum testnet simulation software.

[Ganache](https://truffleframework.com/ganache)

Then, run it. You should see this:

![Image 1](./images/image1.tiff)

Copy the first address. That will be the address you will be using to deploy the smart contract later on.

### Ethereum-Bridge
Next, we set up Ethereum-Bridge, which will use the second address in your Ganache to launch a smart contract to interact with the Oraclize server. This is so that we can use Oracles, to query live ETH prices and flight statuses.

Follow the instructions here:

[Ethereum-Bridge](https://github.com/oraclize/ethereum-bridge)

Once Ethereum-Bridge is successfully installed, go into the folder and do this:

`./ethereum-bridge -H localhost:PORT -a 1`

where `PORT` is the port number to interact with the private testnet, which can be found on Ganache. The default `PORT` is `7545` so if you did not change anything you can just do this:

`./ethereum-bridge -H localhost:7545 -a 1`

Wait for the setup to complete. Once it is done, you should see this: 

![Image 2](./images/image2.tiff)

Copy the line `OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);`. You will need it later when deploying the smart contract.

## Smart Contract Deployment

We will be working with Truffle, a development framework for Ethereum.

Firstly, install truffle by doing the following:

`npm install truffle -g`

Then, install the requirements.txt under the folder `smart_contract`.

`pip3 install -r requirements.txt`

Next, go to `/contracts/Insurance.sol` and change go to the constructor function. You should see this:

    constructor() public {
        OAR = OraclizeAddrResolverI(0xae1783BDfc2e18Ac20C2aaD9F0DdF441b086d256);
        oraclize_setCustomGasPrice(DEFAULT_ORACLE_GWEI); // 2 gwei
        _totalSupply = INITIAL_SUPPLY;
        // for testing
        _mint(owner, 10 * ROUND_TRIP_LP_REWARD);
    }
    
Change the contract address in the `OAR` variable with the one you got previously. 

Next, you can compile the contract by doing:

`truffle compile`

and then deploy the contract:

`truffle migrate`

Once the contract is deployed, go to Ganache, under `Transactions`, and look for the smart contract transaction. The transaction should look like this: 

![Image 3](./images/image3.tiff)


Copy the contract address. You can now test the contract by doing the following, on a Python console:

    import web3
    import json

    w3 = web3.Web3(web3.HTTPProvider("http://localhost:7545"))
    path_to_contract = "/path/to/build/Insurance.json"
    // Should look something like this "./build/contracts/Insurance.json"
    // if you have opened the console in the smart_contract folder
    
    truffle_file = json.load(open(path_to_contract))
    
    myAddress = "YOUR ADDRESS HERE" // The first contract address 
    abi = truffle_file['abi']
    contract_address = "CONTRACT ADDRESS"  # input contract address here
    
    myContract = w3.eth.contract(address=contract_address, abi=abi)

    # check if contract is working
    print(myContract.functions.getOwner().call())

    # put ether into contract
    print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))
    myContract.functions.contribute().transact(
        {"gas": 1000000, "from": myAddress, "value": web3.Web3.toWei(3.0, 'ether')})
    print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))

    # buy round-trip insurance with ether
    print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))  # show prev balance
   	# arguments are tripTypeEnum, insuranceId, flightNumber, beneficiary
    myContract.functions.buyInsurance(1, 5132132, "SQ123", myAddress).transact(
        {"gas": 1000000, "from": myAddress, "value": web3.Web3.toWei(0.3, 'ether')})
    print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))  # show current balance (should be -0.3)

Wait for Oraclize to return the buyInsurance query. It should take about 15 seconds. You can then see that you have purchased the insurance by doing:

    print(myContract.functions.getTicketInsuranceDetails(myAddress).call())
    // should return [1, 5132132, "SQ123"]

If you try to do `buyInsurance` again with the same id (`5132132`), the smart contract will `revert` as the `insuranceId` is already used.

Now, that the smart contract is working, you can use the front-end.

Note: To use the contract, after deployment, make sure to pre-load the contract with ether, as Oracle http queries require ether

	# put ether into contract
    print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))
    myContract.functions.contribute().transact(
        {"gas": 1000000, "from": myAddress, "value": web3.Web3.toWei(3.0, 'ether')})
    print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))

## Front-end Deployment

We use Nodejs for front-end development, mostly using Vue and Bootstrap packages.

To setup the project, firstly navigate to the /path/to/flask/client/ folder, open a terminal console and install the required modules using

`npm i`

After installing, put in the contract address here in the ./src/components/Insurance.vue.

    <script>
        import axios from 'axios';
        import Web3 from 'web3';
        
        var truffle_file = require("../../../../smart_contract/build/contracts/Insurance.json")
        var web3 = new Web3('http://localhost:7545');
        var myContract = new web3.eth.Contract(truffle_file.abi, "<YOUR CONTRACT ADDRESS HERE>");
        myContract.methods.getOwner().call().then((response) => {
          d.getEtherBalance()
          d.getLPBalance()
        })
    
If there is an import error for the contract build, you can also change the path in the variable `truffle_file` to an absolute path.

The project can then be run through

`npm run dev`

Using a prefered browser, enter the address

`localhost:8080/`

and you'll end up at the main page of the application.

The `Front-end Details` section will detail how to navigate the front-end.

## Smart Contract Details

### Smart Contract Functionality
	
    modifier requireMinBuyGas();
    # if function has this modifier, it requires at least 1m gas
    

    modifier requireMinGasPrice();
    # if functon has this modifier, it requires at least DEFAULT_ORACLE_GWEI=2gwei gas price
    
    
    modifier isNotContract();
    # if function has this modifier, it cannot be called by a contract
    
    
	constructor() public; 
      	# links to the Oracle Query Contract,
      	# mints test Loyalty Points for owner,
      	# and sets the default oracle query gas cost to 2 gwei
    
    
    function getOwner() public view returns(address);
    	# returns the contract owner's address (your address)
    
    
    function contribute() public payable;
    	# used to pre-load the contract with Ether
    
    
    function setOracleGasPrice(uint256 w) public onlyOwner;
    	# sets the oracle query gas price
	    # used only if network is loaded
    
    
    function totalSupply() public view returns (uint256);
   		# returns the total supply of Loyalty Points
    
    
    function getTicketInsuranceDetails(address holder) 
    								   public view returns(uint256, string, uint256);
    	# gets the insurance details for a particular address;
        
        
    function buyInsurance(uint8 ticketType, uint256 insuranceId, 
    					  string ticketNumber, address beneficiary) 
                          public payable whenNotPaused requireMinBuyGas isNotContract;
    	# buys insurance
    
    
    function _priceQueryOracle(TicketInsurance ti, address msg_sender, 
    						   address beneficiary, uint256 msg_value_wo_gas,
                               uint8 claim_type, CallBackType cbt) private;
        # queries oraclize for ETHSGD price
    
    
    function buyInsuranceLP(uint8 ticketType, uint256 insuranceId, 
    						string ticketNumber, address beneficiary) public whenNotPaused;
        # buy insurance with Loyalty Points
   
    
    function payout(uint256 insuranceId, uint8 claim_type) 
    				public whenNotPaused requireMinBuyGas isNotContract;
        # payout insurance
    
    
    function checkClaimed(uint256 insuranceId) public view returns (uint8);
    	# check whether insurance is claimed
    
    
    function __callback(bytes32 eventId, string result) public;
    	# callback function called by oraclize_query
    
    
    function _callbackRefund(address msg_sender, uint256 msg_value_wo_gas, bool emit_event) private;
    	# refunds remaining gas to msg.sender in Oraclize callback, since if not manually done,
        # gas refund will be to the Oracle contract instead
    
    
    function balanceOf(address owner) public view returns (uint256);
    	# get Loyalty Points balance
     
     
    function _mint(address account, uint256 value) internal;
    	# mint Loyalty Points
    
    
    function _burn(address account, uint256 value) internal;
    	# burn loyalty points
    
    
    function terminateContract() public onlyOwner;
    	# sends all ETH in the contract to owner
        # used only if contract gets stuck due to bug
        

#### Preloading the contract
Before using the smart contract, it has to be pre-loaded with Ether using the `contribute()` function, as calling the oracle requires a fee.

#### Modifiers
We have three modifiers to regulate function-calling behaviour:

1. `requireMinBuyGas()`, which is used on Oraclized functions, as the oracle call requires a certain amount of gas. 
2. `requireMinGasPrice()`, which is also used on Oraclized functions, as the oracle call requires a minimum gas price, set by `oraclize_setCustomGasPrice(DEFAULT_ORACLE_GWEI)` (2gwei).
3. `isNotContract()`, which prevents contracts from calling the Oraclized functions, as we do not know what is the exact amount of gas to use to refund after the oracle's callback, as we do not know precisely how the contract deals with transfers.

#### Functionality
##### Insurance buying with Ether
We use `buyInsurance(uint8 ticketType, uint256 insuranceId, string ticketNumber, address beneficiary)` to purchase insurance. The arguments are the `ticketType`, which is `1` for round-trip and `2` for one-way, provided by the front-end; `insuranceId`, which is a unique id provided by the front-end for each insurance policy; `ticketNumber`, which is the flight number; and `beneficiary`, which is the address getting the insurance (can be the `msg.sender` himself).

The purchase works by first querying the oracle with an `HTTP GET` for the `ETHSGD`price. After 1-2 blocks, the price will be returned, following which the oracle will call the insurance contract's `__callback()` function. Once it is called, the purchase will be executed if the amount provided is greater than or equal to the price of the insurance policy. Loyalty Points will be minted for the `msg.sender` in the process. The remaining gas and excess ether will be returned to the `msg.sender` through the `_callbackRefund()` function, as the callback does not return the remaining gas to the `msg.sender` but to the oracle contract

##### Insurance buying with Loyalty Points
Purchasing with Loyalty Points works the same way, except that there is no need for an oracle query and a refund function, since the refund to `msg.sender` is the default.

##### Receiving a insurance claim payout
To receive a payout, we call the `payout(uint256 insuranceId, uint8 claim_type)` function. The arguments are `insuranceId`, which is the insurance policy's unique id, and the `claim_type`, which is the type of insurance claim (delayed or cancelled). 

It first checks whether the `insuranceId` exists first. If it does, it queries for the `ETHSGD` price through the oracle. It then, based on the `claim_type`, first checks whether it has enough money to payout. If it does not, it will payout whatever amount it has in the balance.

#### Readers
We have a bunch of readers to check for important state changes. Specifically:
- `getTicketInsuranceDetails(address holder)`, to check the details of an address's current insurance policy.
- `checkClaimed(uint256 insuranceId)`, to check the claim status of an insurance policy
- `balanceOf(address owner)`, to check an address's Loyalty Points balance

#### SafeMath
We use `SafeMath.sol` for `uint256` as it deals with integer overflows of `uint256`. Better to be safe than sorry when it comes to money.

#### Oracle gas usage efficiency
As the oracle queries do not return the remaining gas to the `msg.sender` but to the oracle contract, we minimize the gas consumption by setting how much max gas is needed and what the `oraclize_query()`'s gas price will be. We do that by first setting the gas price for the `oraclize_query()` to 2 gwei, then have a max cap for the amount of gas used for the query to be 750000, and then have a `__callbackRefund()` function within the oracle callback to refund the remaining gas (and ETH in excess to purchase price). 

We also have a `setOracleGasPrice()` function in case gas prices surge in the event of network congestion (e.g. some `ERC721` game becomes popular or ICO season comes back).


#### Problems faced

The smart contract was supposed to check the flight status through the Singapore Airline API for both the purchase and the payout, but we decided to instead only check on the front-end, as it is near impossible to do so via Oraclize. Oraclize does not yet publicly support `HTTP` headers, which we require to send the `apikey`, and even though some of the code in the library does seem to support it (through the use of `oraclize_query("computation))`, we just could not get it to work, no matter what configuration we tried. We will fix this issue once Oraclize supports `HTTP` headers.

    
## Front-end Details

The main page of the application hosts an input line to enter their Ethereum private key. You can use any of the keys in Ganache by pressing the "key" button, except for the second one, as it is used by the Oracle. It is recommended that you use the first "key".

You will then be redirected to the insurance page upon entering a correct Ethereum private key.

Next, input your SIA flight number (eg. SQ392) and the date of your flight. You can get a test flight number from [Changi Departures](http://www.changiairport.com/en/flight/departures.html). The application will then query the SIA API to check if the flight is valid.

You can then choose to purchase either a one-way or a round trip insurance. There is an option to purchase with either Ether or with Loyalty Points.

Once the purchase is successful, the application will add the insurance into the table at the bottom of the webpage with the insurance ID, ticket type, flight number, flight time and status for redemption. Each purchase of insurance with Ether will also give you Loyalty Points, regardless of the flight status.

If the flight is delayed/cancelled, you can come back to this table to click on the redeem button to claim your insurance in Ether. 