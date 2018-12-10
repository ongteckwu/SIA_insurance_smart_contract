import Vue from 'vue'
import Router from 'vue-router'
import HelloWorld from '@/components/HelloWorld'
import Main from '@/components/Main'
import Insurance from '@/components/Insurance'

Vue.use(Router);

export default new Router({
  routes: [
    {
      path: '/',
      name: 'Main',
      component: Main
    },
    {
      path: '/insurance',
      name: 'Insurance',
      component: Insurance
    }
  ],
  mode: 'history'
})
