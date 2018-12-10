<template>
  <div>
    <p style="padding-top:50px"></p>

  	<header>
	  	<h>
	  		<font size="20" color="green">
		  		SIA Flight Insurance
		  	</font>
	  	</h>
  	</header>

    <p style="padding-top:50px"></p>

    <p>{{msg}}</p>

    <div id="input_address">
      <b-form-input v-model = "input_address" type="text" placeholder = "Enter Ethereum private key here" size = 50px></b-form-input>
    </div>

    <p style="padding-top:20px"></p>

    <button
    	type="button"
    	class="btn btn-success btn-sm"
    	size = 50px
    	@click="onCheckAddress(input_address)"
    	>
	  Next
	</button>
  </div>
</template>

<script>
import axios from 'axios';
import router from '../router';
import util from 'ethereumjs-util';

export default {
  name: 'Main',
  data() {
    return {
    addresses:[],
    msg: '',
    };
  },
  components: {

  },
  methods: {
	  onCheckAddress(address){
         // "a983206d28e7b85fda0948f8974ae8a7c1184d413bd7ffd9676395d0b54ac94e"
    if (!util.isValidPrivate(Buffer.from(address, "hex"))) {
      alert("Not a valid key")
      return
    }
    router.push("Insurance")
    this.msg = '0x' + util.privateToAddress(Buffer.from(address, "hex")).toString('hex')
    localStorage.private = address
    localStorage.public = this.msg
	  }
  }
};
</script>