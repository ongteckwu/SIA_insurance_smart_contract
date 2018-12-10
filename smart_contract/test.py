import web3
import json

w3 = web3.Web3(web3.HTTPProvider("http://localhost:7545"))
path_to_contract = "./build/contracts/Insurance.json"
truffle_file = json.load(open(path_to_contract))

myAddress = "0xF5C1281ca9cE005d9F78C511147aF32DD3ef9240"
abi = truffle_file['abi']
contract_address = "0xB0d54Ae14EAeAfCD45657BE1099F702d8F0A7e60"  # input contract here
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
myContract.functions.buyInsurance(1, 123, "ABC", myAddress).transact(
    {"gas": 1000000, "from": myAddress, "value": web3.Web3.toWei(0.3, 'ether')})
print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))  # show current balance
# wait 20 seconds
print(myContract.functions.getTicketInsuranceDetails(myAddress).call())

# buy round-trip insurance with insufficient ether (invokes refund)
print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))  # show prev balance
myContract.functions.buyInsurance(1, 32323, "ABCDE", myAddress).transact(
    {"gas": 1000000, "from": myAddress, "value": web3.Web3.toWei(0.1, 'ether')})
print("%feth" % (w3.eth.getBalance(myAddress) / 10**18))  # show current balance

# buy round-trip insurance with LP
print("%fLP" % (myContract.functions.balanceOf(myAddress).call() / 10**18)) # show prev LP balance
myContract.functions.buyInsuranceLP(1, 1234, "ABCD", myAddress).transact(
    {"gas": 100000, "from": myAddress, "value": web3.Web3.toWei(0, 'ether')})
print("%fLP" % (myContract.functions.balanceOf(myAddress).call() / 10**18)) # show remaining LP balance
print(myContract.functions.getTicketInsuranceDetails(myAddress).call())
# show remaining LP balance

# payout
myContract.functions.payout(123, 1).transact(
    {"gas": 1000000, "from": myAddress, "value": web3.Web3.toWei(0, 'ether')})
print(myContract.functions.checkClaimed(123).call())

# retrieve remaining ether in contract
print(myContract.functions.terminateContract().transact(
    {"gas": 100000, "from": myAddress, "value": web3.Web3.toWei(0, 'ether')}))

# ESTIMATE GAS PRICE
myContract.functions.buyInsurance(1, 123, "ABC").estimateGas({"gas": 5000000})
myContract.functions.getOwner().estimateGas()

# Contract test
path_to_contract2 = "/Users/teckwuong/erc20/build/contracts/ExampleOracle.json"
truffle_file2 = json.load(open(path_to_contract2))

myAddress = "0xF5C1281ca9cE005d9F78C511147aF32DD3ef9240"
abi2 = truffle_file2['abi']
contract_address2 = "0xF28D6B208b6E66959F3a5f1aCDBD10F19bA025f9"
myContract2 = w3.eth.contract(address=contract_address2, abi=abi2)

tx_hash = myContract2.functions.updatePrice().transact(
    {"gas": 5000000, "from": myAddress, "value": web3.Web3.toWei(0.00, 'ether')})
tx_receipt = w3.eth.getTransactionReceipt(tx_hash)
myContract2.events.LogNewOraclizeQuery().processReceipt(tx_receipt)
myContract2.events.LogNewOraclizeQuery().createFilter(fromBlock=0, toBlock="latest").get_all_entries()
myContract2.eventFilter('LogNewOraclizeQuery', {'fromBlock': 0, 'toBlock': 'latest'}).get_all_entries()

# filter events
myContract.events.BuyInsuranceEvent().createFilter(fromBlock=0).get_all_entries()
