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
      req = @buildApiRequest 'GET', '/youtube/v3/subscriptions',
        mine: true
        part: 'snippet,contentDetails'
        maxResults: 50
      req.execute (resp) =>
        @channels = resp.items
