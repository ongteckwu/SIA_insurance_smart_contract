<template>
  <div>

  <p style="padding-top:20px"></p>

    <span>
      <font size="4" color="grey">
            Your public address: {{text}}
      </font>
    </span>
    
    <header>
      <h>
        <font size="20" color="green">
          SIA Flight Insurance
        </font>
      </h>
    </header>

  <p style="padding-top:20px"></p>

  <div style="width:200px; margin-left:auto; margin-right:auto" >
    <b-form-input
      id = "check_flight"
      v-model.trim = "flight_input"
      :state = "nameState"
      aria-describedby= "inputLiveFeedback"
      type="text"
      placeholder = "Enter your flight number here"
      ></b-form-input>
      <b-form-invalid-feedback id="inputLiveFeedback">
      <!-- This will only be shown if the preceeding input has an invalid state -->
        Enter a valid SQ flight
      </b-form-invalid-feedback>


    <b-form-input v-model = "date_input" type="date"
      id = "check_date"
      v-model.trim = "date_input"
    >
    </b-form-input>


    <button
      type="button"
      class="btn btn-warning btn-m"
      :disabled='!isComplete'
      @click="onAddFlightDetails()"
      >
      Enter
    </button>
  </div>

  <p style="padding-top:20px"></p>


  <p id="loading" style="visibility:hidden">
    {{loading_text}}
  </p>
  <p id="show_flight" style="visibility:hidden">
    Flight: SQ{{flight_no}} Date: {{date_input}}

  </p>

  <table class="table table-borderless">
    <tr>
      <th>
        Ethereum balance:
      </th>
      <th>
        Loyalty points balance:
      </th>
    </tr>
    <tr>
      <td>
        <font size="15" color="green">
          {{ether}} ETH
        </font>
      </td>
      <td>
        <font size="15" color="darkblue">
        {{lp}} LP
        </font>
      </td>
    </tr>
    <tr id="btnbuy">
      <td>
        <button
          id="btnbuyethow"
          type="button"
          class="btn btn-success btn-m"
          disabled=""

          @click="onBuyInsuranceETHOneWay()"
          >
        Purchase One-Way
        </button>
        <button
          id="btnbuyethrt"
          type="button"
          class="btn btn-success btn-m"
          disabled=""

          @click="onBuyInsuranceETHRoundTrip()"
          >
        Purchase Round Trip
        </button>
      </td>
      <td>  
        <button
          id="btnbuylpow"
          type="button"
          class="btn btn-primary btn-m"
          disabled=""

          @click="onBuyInsuranceLPOneWay()"
          >
        Purchase One-Way
        </button>
        <button
          id="btnbuylprt"
          type="button"
          class="btn btn-primary btn-m"
          disabled=""

          @click="onBuyInsuranceLPRoundTrip()"
          >
        Purchase Round Trip
        </button>
      </td>
    </tr>
    <tr>
      <td>
        Current price - one-way (S$20): {{eth_val}} ETH
      </td>
    </tr>  
    <tr>
      <td>
        Current price - round trip (S$30): {{eth_val2}} ETH
      </td>
    </tr>  
  </table>

  <p id="redeem" style="visibility:hidden"> We have made redeeming possible even though the flight might be on schedule. Try pressing "Redeem". </p>
  <p style="padding-top:50px"></p>

  <table class="table table-hover">
    <thead>
      <tr>
        <th scope="col">Id</th>
        <th scope="col">Ticket Type</th>
        <th scope="col">Flight</th>
        <th scope="col">Time</th>
        <th scope="col">Status</th>
        <th scope="col">Redeem</th>
        <th></th>
      </tr>
    </thead>

    <tbody>
        <tr v-for="val in flight_vals">
          <th scope="row">{{val.id}}</th>
          <td>{{val.ticket_type}}</td>
          <td>{{val.name}}</td>
          <td>{{val.time}}</td>
          <td>{{val.status}}</td>
          <td>
            <button
                type="button"
                class="btn btn-warning btn-sm"
                @click="onClickRedeem(val.id)">
              Redeem
            </button>
          </td>
      </tr>
    </tbody>
  </table>

    <div style="justify-content:center" id="no_insurance">
      No Insurances Bought
    </div>
  </div>
</template>

<script>
import axios from 'axios';
import Web3 from 'web3';

var truffle_file = require("../../../../smart_contract/build/contracts/Insurance.json")
var web3 = new Web3('http://localhost:7545');
var myContract = new web3.eth.Contract(truffle_file.abi, "0xB0d54Ae14EAeAfCD45657BE1099F702d8F0A7e60");
myContract.methods.getOwner().call().then((response) => {
  d.getEtherBalance()
  d.getLPBalance()
})
var d = {
      getEtherBalance: async function() {
      var th = this
      web3.eth.getBalance(localStorage.public).then((resp) => {
        th.ether = Math.floor(resp / 10**14) / 10**4;
      })
    },
    getLPBalance: async function() {
      var th = this
      myContract.methods.balanceOf(localStorage.public).call().then((resp) => {
        th.lp = resp / 10**18;
      })
    },
    generateId: function(n) {
        var add = 1, max = 12 - add;   // 12 is the min safe number Math.random() can generate without it starting to pad the end with zeros.   

        if ( n > max ) {
                return d.generateId(max) + d.generateId(n - max);
        }

        max        = Math.pow(10, n+add);
        var min    = max/10; // Math.pow(10, n) basically
        var number = Math.floor( Math.random() * (max - min + 1) ) + min;

        return ("" + number).substring(add); 
}
}

export default {
  name: 'Main',
  data() {
    return {
      text: localStorage.public,
      ether: 0.0,
      lp: 0.0,
      flight_input: '',
      flight_no: 0,
      date_input: new Date(),
      eth_val: 0.0,
      eth_val2: 0.0,
      flight_id: '',
      // flight_name: '',
      // flight_time: '',
      // flight_status: '',
      flight_redeem: '',
      flight_vals: [],
      flight_response: new Object(),
      loading_text: '',
    };
  },
  mounted: {

  },
  created: async function(){
    // await this.getEtherValue()

    setInterval(this.getEtherValue(), 600000)
    setInterval(this.getEtherBalance(), 600000)
    setInterval(this.getLPBalance(), 600000)
  },
  computed: {
    nameState(){
      return (this.flight_input.substring(0,2)=="SQ" && this.flight_input.length > 3 && this.flight_input.length < 7 && !isNaN(this.flight_input.substring(2,this.flight_input.length))) ? true : false
    },
    isComplete(){
      return this.flight_input && this.date_input
    }
  },
  methods: {

    onAddFlightDetails(){

      const proxyurl = "https://cors-anywhere.herokuapp.com/";

      var request = require('request')

      this.flight_no = parseInt(this.flight_input.substring(2, this.flight_input.length))
      this.loading_text = "loading....."

      var load = document.getElementById("loading")
      load.style.visibility = 'visible'
      var elem = document.getElementById("show_flight")
      elem.style.visibility = 'hidden'
      var th = this


      request.post({
        headers: {'apikey': '8y3yb95dmyxc3pfe2sp73ujb', 'Content-Type': 'application/json'},
        url: proxyurl + 'https://apigw.singaporeair.com/api/v3/flightstatus/getbynumber',
        json: {  "request":{
            "airlineCode":"SQ",
            "flightNumber": this.flight_no.toString(),
            "scheduledDepartureDate": this.date_input,
            },
          "clientUUID":"TestIODocs"},
      },
      function callback(error, response, body){
         // this.flight_response = body
          console.log(body.status)
          if(body.status == "SUCCESS"){
            var load = document.getElementById("loading")
            var elem = document.getElementById("show_flight")
            load.style.visibility = 'hidden'
            elem.style.visibility = 'visible'
            localStorage.flight_name = "SQ" + body['response']['flights']['0']['legs']['0']['flightNumber']
            localStorage.flight_status = body['response']['flights']['0']['legs']['0']['flightStatus']
            localStorage.flight_time = body['response']['flights']['0']['legs']['0']['scheduledDepartureTime']

            var btn1 = document.getElementById("btnbuyethow")
            var btn2 = document.getElementById("btnbuyethrt")
            var btn3 = document.getElementById("btnbuylpow")
            var btn4 = document.getElementById("btnbuylprt")
            btn1.disabled=false
            btn2.disabled=false
            btn3.disabled=false
            btn4.disabled=false

          }
          else if(body.status == "FAILURE"){
            var load = document.getElementById("loading")
            th.loading_text = "Wrong flight/date. Please visit http://www.changiairport.com/en/flight/departures.html and get an SQ flight to key in, with the correct date."

            var btn1 = document.getElementById("btnbuyethow")
            var btn2 = document.getElementById("btnbuyethrt")
            var btn3 = document.getElementById("btnbuylpow")
            var btn4 = document.getElementById("btnbuylprt")
            btn1.disabled=true
            btn2.disabled=true
            btn3.disabled=true
            btn4.disabled=true
          }
      });
    },
    onBuyInsuranceETHOneWay(){
      if(localStorage.flight_name.length > 2){
        var elem = document.getElementById("no_insurance")
        elem.style.visibility = 'hidden'
        var elem2 = document.getElementById("show_flight")
        elem2.style.visibility = 'hidden'
        var load = document.getElementById("loading")
        load.style.visibility = 'visible'
        var id = d.generateId(32)
        this.loading_text = "Hold on! Processing your insurance policy... (takes about 30 seconds as we need to wait for the Oracle to callback)"
        myContract.methods.buyInsurance("0", id, localStorage.flight_name, localStorage.public).send(
            {"gas": "1000000", "from": localStorage.public, "value": web3.utils.toWei(this.eth_val2.toString())}).then((resp) => {
                localStorage.flight_id = id;
                localStorage.ticket_type = "One Way"
                this.getEtherBalance()
                this.getLPBalance()
                setTimeout(this.addToTable, 30000);
            })
        var btn1 = document.getElementById("btnbuyethow")
        var btn2 = document.getElementById("btnbuyethrt")
        var btn3 = document.getElementById("btnbuylpow")
        var btn4 = document.getElementById("btnbuylprt")
        btn1.disabled=true
        btn2.disabled=true
        btn3.disabled=true
        btn4.disabled=true
        this.addToTable()
      }
    },    
    onBuyInsuranceETHRoundTrip(){
      if(localStorage.flight_name.length > 2){
        var elem = document.getElementById("no_insurance")
        elem.style.visibility = 'hidden'
        var elem2 = document.getElementById("show_flight")
        elem2.style.visibility = 'hidden'
        var load = document.getElementById("loading")
        load.style.visibility = 'visible'
        var id = d.generateId(32)
        this.loading_text = "Hold on! Processing your insurance policy... (takes about 30 seconds as we need to wait for the Oracle to callback)"
        myContract.methods.buyInsurance("1", id, localStorage.flight_name, localStorage.public).send(
            {"gas": "1000000", "from": localStorage.public, "value": web3.utils.toWei(this.eth_val2.toString())}).then((resp) => {
                localStorage.flight_id = id;
                localStorage.ticket_type = "Round Trip"
                this.getEtherBalance()
                this.getLPBalance()
                setTimeout(this.addToTable, 30000);
            })
        var btn1 = document.getElementById("btnbuyethow")
        var btn2 = document.getElementById("btnbuyethrt")
        var btn3 = document.getElementById("btnbuylpow")
        var btn4 = document.getElementById("btnbuylprt")
        btn1.disabled=true
        btn2.disabled=true
        btn3.disabled=true
        btn4.disabled=true
      }
    },
    onBuyInsuranceLPOneWay(){
      if(localStorage.flight_name.length > 2){
        var elem = document.getElementById("no_insurance")
        elem.style.visibility = 'hidden'
        var elem2 = document.getElementById("show_flight")
        elem2.style.visibility = 'hidden'
        var load = document.getElementById("loading")
        load.style.visibility = 'visible'
        var id = d.generateId(32)
        this.loading_text = "Hold on! Processing your insurance policy..."
        myContract.methods.buyInsuranceLP("2", id, localStorage.flight_name, localStorage.public).send(
            {"gas": "100000", "from": localStorage.public, "value": web3.utils.toWei("0")}).then((resp) => {
                localStorage.flight_id = id;
                localStorage.ticket_type = "One Way"
                this.getEtherBalance()
                this.getLPBalance()
                this.addToTable()
            })
        var btn1 = document.getElementById("btnbuyethow")
        var btn2 = document.getElementById("btnbuyethrt")
        var btn3 = document.getElementById("btnbuylpow")
        var btn4 = document.getElementById("btnbuylprt")
        btn1.disabled=true
        btn2.disabled=true
        btn3.disabled=true
        btn4.disabled=true
      }
    },    
    onBuyInsuranceLPRoundTrip(){
      if(localStorage.flight_name.length > 2){
        var elem = document.getElementById("no_insurance")
        elem.style.visibility = 'hidden'
        var elem2 = document.getElementById("show_flight")
        elem2.style.visibility = 'hidden'
        var load = document.getElementById("loading")
        load.style.visibility = 'visible'
        var id = d.generateId(32)
        this.loading_text = "Hold on! Processing your insurance policy..."
        myContract.methods.buyInsuranceLP("1", id, localStorage.flight_name, localStorage.public).send(
            {"gas": "100000", "from": localStorage.public, "value": web3.utils.toWei("0")}).then((resp) => {
                localStorage.flight_id = id;
                localStorage.ticket_type = "Round Trip"
                this.getEtherBalance()
                this.getLPBalance()
                this.addToTable()
            })
        var btn1 = document.getElementById("btnbuyethow")
        var btn2 = document.getElementById("btnbuyethrt")
        var btn3 = document.getElementById("btnbuylpow")
        var btn4 = document.getElementById("btnbuylprt")
        btn1.disabled=true
        btn2.disabled=true
        btn3.disabled=true
        btn4.disabled=true
      }
    },
    getEtherData: async function() {
      var request_promise = require('request-promise')
      var resp = request_promise.get('https://cors-anywhere.herokuapp.com/https://api.coinmarketcap.com/v2/ticker/1027/?convert=SGD&fbclid=IwAR2UqbEowWL495nG-idfAE5rIJDUEUmGKxBFqYuv4bWLRk2MxCH97jHVHYo')
      return resp
    },
    getEtherValue: async function(){
      var r = await this.getEtherData()
      var r1 = JSON.parse(r)
      var price = r1.data.quotes.SGD.price
      this.eth_val = Math.round(20/price*10000 + 5)/10000
      this.eth_val2 = Math.round(30/price*10000 + 5)/10000
    },
    getEtherBalance: d.getEtherBalance,
    getLPBalance: d.getLPBalance,
    addToTable(){
      var redeem = document.getElementById("redeem")
      redeem.style.visibility = "visible"
      this.loading_text = "Insurance policy registered!"
      this.flight_vals.push({id:localStorage.flight_id, ticket_type: localStorage.ticket_type, name:localStorage.flight_name, time:localStorage.flight_time, status:localStorage.flight_status})
    },
    removeFromTable(id) {
      for (var i = 0; i < this.flight_vals.length; i++) {
        if (this.flight_vals[i].id == id) {
          this.flight_vals.splice(i, 1);
          break;
        }
      }
      if (this.flight_vals.length == 0) {
      var redeem = document.getElementById("redeem")
      redeem.style.visibility = "hidden"
      var elem = document.getElementById("no_insurance")
      elem.style.visibility = 'visible'        
      }
    },
    onClickRedeem(id){
      var elem2 = document.getElementById("show_flight")
      elem2.style.visibility = 'hidden'
      var load = document.getElementById("loading")
      load.style.visibility = 'visible'
      this.loading_text = "Hold on! Checking Claim..."
      myContract.methods.payout(id, 1).send(
          {"gas": "1000000", "from": localStorage.public, "value": web3.utils.toWei("0")}).then((resp) => {
              this.loading_text = "Claim Received!"
              this.getEtherBalance()
              this.getLPBalance()
              this.removeFromTable(id)
          })
    }
  }
};
</script>



