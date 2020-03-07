app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  mixins: [
    window.goog
  ]

  mounted: ->
    @auth.signIn()
