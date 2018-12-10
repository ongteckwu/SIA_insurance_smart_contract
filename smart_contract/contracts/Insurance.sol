pragma solidity ^0.4.24;

import "./Oraclize.sol";
import "./math/SafeMath.sol";
import "./Pausable.sol";


contract Insurance is Pausable, usingOraclize {
    using SafeMath for uint256;

    event BuyInsuranceEvent(bool success, address beneficiary, uint8 ticketType, uint256 amount, uint256 lp_amount);
    event LogNewOraclizeQuery(string description);
    event LogPriceUpdated(string price);

    // balance of loyalty points
    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;
    string  public constant name = "Loyalty Points";
    string  public constant symbol = "LP";
    uint8   public constant decimals = 18;

    uint256 private ETHSGD;
    uint256 public constant INITIAL_SUPPLY = 0;
    uint256 public constant ROUND_TRIP_LP_COST = 150 * (10 ** uint256(decimals));
    uint256 public constant ONE_WAY_LP_COST = 100 * (10 ** uint256(decimals));
    uint256 public constant ROUND_TRIP_LP_REWARD = 30 * (10 ** uint256(decimals));
    uint256 public constant ONE_WAY_LP_REWARD = 10 * (10 ** uint256(decimals));
    uint256 public constant ROUND_TRIP_SGD_PRICE = 30 ether; // ether = 10**18 (wei calculation; ignore)
    uint256 public constant ONE_WAY_SGD_PRICE = 20 ether; // ether = 10**18 (wei calculation; ignore)
    uint256 public constant DELAYED_CLAIM_AMOUNT = 200 ether; // ether = 10**18 (wei calculation; ignore)
    uint256 public constant CANCELLED_CLAIM_AMOUNT = 5000 ether; // ether = 10**18 (wei calculation; ignore)
    uint256 public DEFAULT_ORACLE_GWEI = 2000000000;
    uint256 public CURRENT_ORACLE_GWEI = DEFAULT_ORACLE_GWEI;
    uint256 private constant MAX_QUERY_GAS = 750000;
    uint256 private constant MIN_BUY_INSURANCE_GAS = 950000;
    uint256 private constant DEFAULT_TRANSFER_GAS = 21000;


    enum TicketType {
        None,
        RoundTrip,
        OneWay
    }

    enum ClaimedType {
        None,
        Delay,
        Cancel
    }

    enum CallBackType {
        None,
        Purchase,
        Payout
    }

    struct TicketInsurance {
        uint256 insuranceId; // given by contract
        string ticketNumber; // of flight
        TicketType ticketType;
    }

    // each address can only have one ticket insurance
    mapping (address => TicketInsurance) private _insurance_map;
    // each insuranceId is mapped to an address
    mapping (uint256 => address) private _owner_map;
    // each insuranceId is mapped to whether it is claimed or not
    mapping (uint256 => ClaimedType) private _claimed_map;
    // eventId to TicketInsurance; for callback purchase
    mapping (bytes32 => TicketInsurance) private _event_map;
    // eventId to beneficiary
    mapping (bytes32 => address) private _event_beneficiary_map;
    // eventId to msg_sender
    mapping (bytes32 => address) private _event_msg_sender_map;
    // eventId to msg_value_wo_gas
    mapping (bytes32 => uint256) private _event_msg_value_map;
    // eventId to  CallBackType
    mapping (bytes32 => CallBackType) private _event_callbacktype_map;
    // eventId to uint8 ClaimedType
    mapping (bytes32 => uint8) private _event_claimedtype_map;

    modifier requireMinBuyGas() {
        require(gasleft() >= MIN_BUY_INSURANCE_GAS, "Gas should be at least 1m");
        _;
    }

    modifier requireMinGasPrice() {
        require(tx.gasprice >= CURRENT_ORACLE_GWEI, "Gas price should be minimally CURRENT_ORACLE_GWEI");
        _;
    }

    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size <= 0, "Address should not be a contract one as oracle callback not configured to payout to a contract");
        _;
    }

    constructor() public {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        oraclize_setCustomGasPrice(DEFAULT_ORACLE_GWEI); // 2 gwei
        _totalSupply = INITIAL_SUPPLY;
        // for testing
        _mint(owner, 10 * ROUND_TRIP_LP_REWARD);
    }

    function getOwner() public view returns(address) {
        return(owner);
    }

    function contribute() public payable {
        // put ether into contract
    }

    function setOracleGasPrice(uint256 w) public onlyOwner {
        oraclize_setCustomGasPrice(w);
        CURRENT_ORACLE_GWEI = w;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getTicketInsuranceDetails(address holder) public view returns(uint256, string, uint256) {
        require(_insurance_map[holder].insuranceId != 0 && _insurance_map[holder].ticketType != TicketType.None, "InsuranceId does not exist");
        return (_insurance_map[holder].insuranceId, _insurance_map[holder].ticketNumber, uint(_insurance_map[holder].ticketType));
    }

    function buyInsurance(uint8 ticketType, uint256 insuranceId, string ticketNumber, address beneficiary) public payable whenNotPaused requireMinBuyGas isNotContract {
        // replaces the current insurance if the beneficiary has one already

        // check if insuranceId already exists
        require(_owner_map[insuranceId] == address(0), "InsuranceId already exists");

        TicketInsurance memory ti;

        if (ticketType == uint8(TicketType.RoundTrip)) {
            ti = TicketInsurance(insuranceId, ticketNumber, TicketType.RoundTrip);
            // subtract MIN_BUY_INSURANCE_GAS as it will be used for the oracle
            // MAX_QUERY_GAS < MIN_BUY_INSURANCE_GAS
            // tx.gasprice >= CURRENT_ORACLE_GWEI
            _priceQueryOracle(ti, msg.sender, beneficiary, msg.value - (MIN_BUY_INSURANCE_GAS * tx.gasprice), 0,  CallBackType.Purchase);
        } 
        else if (ticketType == uint8(TicketType.OneWay)) {
            ti = TicketInsurance(insuranceId, ticketNumber, TicketType.OneWay);
            _priceQueryOracle(ti, msg.sender, beneficiary, msg.value - (MIN_BUY_INSURANCE_GAS * tx.gasprice), 0, CallBackType.Purchase);
        }
        else {
            emit BuyInsuranceEvent(false, 0, 0, 0 ,0);
            revert("Ticket Type does not exist");
        }
    }

    function _priceQueryOracle(TicketInsurance ti, address msg_sender, address beneficiary, uint256 msg_value_wo_gas, uint8 claim_type, CallBackType cbt) private {
        if (oraclize_getPrice("URL") > address(this).balance) {
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        }
        else {
            bytes32 eventId = oraclize_query("URL", "json(https://api.coinmarketcap.com/v2/ticker/1027/?convert=SGD).data.quotes.SGD.price", MAX_QUERY_GAS);
            if (cbt == CallBackType.Purchase) {
                _event_beneficiary_map[eventId] = beneficiary;
            }
            else if (cbt == CallBackType.Payout) {
                _event_claimedtype_map[eventId] = claim_type;
            }
            _event_map[eventId] = ti;
            _event_msg_sender_map[eventId] = msg_sender;
            _event_msg_value_map[eventId] = msg_value_wo_gas;
            _event_callbacktype_map[eventId] = cbt;
        }
    }

    function buyInsuranceLP(uint8 ticketType, uint256 insuranceId, string ticketNumber, address beneficiary) public whenNotPaused {
        // replaces the current insurance if the beneficiary has one already
        
        // check if insuranceId already exists
        require(_owner_map[insuranceId] == address(0), "InsuranceId already exists");

        TicketInsurance memory ti;

        if (ticketType == uint(TicketType.RoundTrip)) {
            if (_balances[msg.sender] < ROUND_TRIP_LP_COST) {
                emit BuyInsuranceEvent(false, 0, 0, 0 ,0);
                revert("Not enough LP to buy RT ticket");
            }

            _burn(msg.sender, ROUND_TRIP_LP_COST);

            ti = TicketInsurance(insuranceId, ticketNumber, TicketType.RoundTrip);

            _insurance_map[beneficiary] = ti;

            _owner_map[ti.insuranceId] = beneficiary;

            emit BuyInsuranceEvent(true, beneficiary, ticketType, 0, ROUND_TRIP_LP_COST);
        } 
        else if (ticketType == uint(TicketType.OneWay)) {
            if (_balances[msg.sender] < ONE_WAY_LP_COST) {
                emit BuyInsuranceEvent(false, 0, 0, 0 ,0);
                revert("Not enough LP to buy OW ticket");
            }

            _burn(msg.sender, ONE_WAY_LP_COST);

            ti = TicketInsurance(insuranceId, ticketNumber, TicketType.OneWay);

            _insurance_map[beneficiary] = ti; 

            _owner_map[ti.insuranceId] = beneficiary;           

            emit BuyInsuranceEvent(true, beneficiary, ticketType, 0, ONE_WAY_LP_COST);
        }
        else {
            emit BuyInsuranceEvent(false, 0, 0, 0 ,0);
            revert("Ticket Type does not exist");
        }
    }

    function payout(uint256 insuranceId, uint8 claim_type) public whenNotPaused requireMinBuyGas isNotContract payable {
        require(_owner_map[insuranceId] != address(0), "InsuranceId does not exist");
        TicketInsurance memory ti;
        ti.insuranceId = insuranceId;
        _priceQueryOracle(ti, msg.sender, address(0), msg.value - (MIN_BUY_INSURANCE_GAS * tx.gasprice), claim_type, CallBackType.Payout);
    } 

    function checkClaimed(uint256 insuranceId) public view returns (uint8) {
        return uint8(_claimed_map[insuranceId]);
    }

    function __callback(bytes32 eventId, string result) public {
        if (msg.sender != oraclize_cbAddress()) revert("Not cbAddress");
        // if result >= prev block time + 2h 15 min
        // allow purchase (code in buyInsuranceLP)
        // round up by + 1
        ETHSGD = parseInt(result) + 1;

        TicketInsurance memory ti;

        if (_event_callbacktype_map[eventId] == CallBackType.Purchase) {
            ti = _event_map[eventId];

            address msg_sender = _event_msg_sender_map[eventId];
            uint256 msg_value_wo_gas = _event_msg_value_map[eventId];

            // ticket insurance does not exist
            if (ti.insuranceId == 0) {
                _callbackRefund(msg_sender, msg_value_wo_gas, true);
                // revert("Ticket type does not exist");
            }

            address beneficiary = _event_beneficiary_map[eventId];

            if (ti.ticketType == TicketType.RoundTrip) {
                if (msg_value_wo_gas * ETHSGD <= ROUND_TRIP_SGD_PRICE) {
                    _callbackRefund(msg_sender, msg_value_wo_gas, true);     
                    // revert("Not enough $$ to buy RT ticket"); 
                }

                _insurance_map[beneficiary] = ti;

                _owner_map[ti.insuranceId] = beneficiary;

                _mint(msg_sender, ROUND_TRIP_LP_REWARD);

                emit BuyInsuranceEvent(true, beneficiary, uint8(ti.ticketType), msg_value_wo_gas, 0);

                delete _event_map[eventId];
                delete _event_beneficiary_map[eventId];
                delete _event_msg_sender_map[eventId];
                delete _event_msg_value_map[eventId];
            }
            else if (ti.ticketType == TicketType.OneWay) {
                if (msg_value_wo_gas * ETHSGD <= ONE_WAY_SGD_PRICE) {
                    _callbackRefund(msg_sender, msg_value_wo_gas, true);
                }

                _insurance_map[beneficiary] = ti;

                _owner_map[ti.insuranceId] = beneficiary;

                _mint(msg_sender, ONE_WAY_LP_REWARD);

                emit BuyInsuranceEvent(true, beneficiary, uint8(ti.ticketType), msg_value_wo_gas, 0);

                delete _event_map[eventId];
                delete _event_beneficiary_map[eventId];
                delete _event_msg_sender_map[eventId];
                delete _event_msg_value_map[eventId];
            }
            else {
                _callbackRefund(msg_sender, msg_value_wo_gas, true);
                // revert("Ticket Type does not exist. In callback.");
            }
        // END OF FUNCTION
        _callbackRefund(msg_sender, 0, false);
        }
        else if (_event_callbacktype_map[eventId] == CallBackType.Payout) {
            ti = _event_map[eventId];
            ClaimedType current_claimed = _claimed_map[ti.insuranceId];
            uint256 claim_amount = 0;
            uint8 claim_type = _event_claimedtype_map[eventId];
            if (claim_type == uint8(ClaimedType.Delay)) {
                if (current_claimed == ClaimedType.None) {
                    claim_amount = (address(this).balance * ETHSGD) < DELAYED_CLAIM_AMOUNT ? address(this).balance : (DELAYED_CLAIM_AMOUNT / ETHSGD);
                    _claimed_map[ti.insuranceId] = ClaimedType.Delay;
                    _owner_map[ti.insuranceId].transfer(claim_amount);
                }
            }
            else if (claim_type == uint8(ClaimedType.Cancel)) {
                if (current_claimed == ClaimedType.None) {
                    claim_amount = (address(this).balance * ETHSGD) < CANCELLED_CLAIM_AMOUNT ? address(this).balance : (DELAYED_CLAIM_AMOUNT / ETHSGD);
                    _claimed_map[ti.insuranceId] = ClaimedType.Cancel;
                    _owner_map[ti.insuranceId].transfer(claim_amount);
                }
                else if (current_claimed == ClaimedType.Delay) {
                    claim_amount = (address(this).balance * ETHSGD) < (CANCELLED_CLAIM_AMOUNT - DELAYED_CLAIM_AMOUNT) ? address(this).balance : ((CANCELLED_CLAIM_AMOUNT - DELAYED_CLAIM_AMOUNT) / ETHSGD);
                    _claimed_map[ti.insuranceId] = ClaimedType.Cancel;
                    _owner_map[ti.insuranceId].transfer(claim_amount);
                }
            }
        }
    }

    function _callbackRefund(address msg_sender, uint256 msg_value_wo_gas, bool emit_event) private {
        if (emit_event) {
            emit BuyInsuranceEvent(false, 0, 0, 0 ,0);
        }
        // // refund
        // // tx.gasprice == CURRENT_ORACLE_GWEI
        msg_sender.transfer(msg_value_wo_gas + ((gasleft() - DEFAULT_TRANSFER_GAS) * CURRENT_ORACLE_GWEI));  
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
    }

    function terminateContract() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}