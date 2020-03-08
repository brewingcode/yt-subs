app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []

  mixins: [
    window.goog
  ]

  created: ->
    await @signIn()

  methods:
    getChannels: ->
      resp = await @apiRequest 'GET', '/youtube/v3/subscriptions',
        mine: true
        part: 'snippet,contentDetails'
        maxResults: 50
      @channels = resp.items
