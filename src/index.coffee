app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []
    order: []
    headers: [
      { value: 'index', text: 'Order', sort: @sortIndex }
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
        channelId = item.snippet.resourceId.channelId # NOT item.snippet.channelId
        if @order.length
          index = @order.indexOf(channelId)
          index = if index >= 0 then index else resp.items.length
        return {
          ..._.pick item.snippet, ['title', 'publishedAt']
          ..._.pick item.contentDetails, ['totalItemCount', 'newItemCount']
          index: index + 1
          channelId
        }

    readStorage: ->
      try
        state = JSON.parse localStorage.getItem 'yt-subs'
        @order = state.order if state.order

    writeStorage: ->
      localStorage.setItem 'yt-subs', JSON.stringify
        order: _.sortBy(@channels, 'index').map (c) -> c.channelId

    sortIndex: (a, b) ->
      if +a < +b
        -1
      else if +a > +b
        1
      else
        0

    setIndex: _.debounce (item, newIndex) ->
      item.index = newIndex
      app.writeStorage()
    , 500
