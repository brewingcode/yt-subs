app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []
    order: []
    headers: [
      { value: 'index', text: 'Order' }
      { value: 'title', text: 'Channel Name' }
      { value: 'totalItemCount', text: 'Item Count' }
    ]

  mixins: [
    window.goog
  ]

  created: ->
    await @signIn()
    @readStorage()

  methods:
    getChannels: ->
      resp = await @apiRequest 'GET', '/youtube/v3/subscriptions',
        mine: true
        part: 'snippet,contentDetails'
        maxResults: 50

      @channels = resp.items.map (item, index) =>
        if @order.length
          index = @order.indexOf(item.snippet.channelId)
          index = if index >= 0 then index else resp.items.length
        return {
          ..._.pick item.snippet, ['title', 'publishedAt', 'channelId']
          ..._.pick item.contentDetails, ['totalItemCount', 'newItemCount']
          index
        }

    readStorage: ->
      try
        state = JSON.parse localStorage.getItem 'yt-subs'
        @order = state.order if state.order

    writeStorage: ->
      localStorage.setItem 'yt-subs', JSON.stringify
        order: @order
