getVideosInChannel = _.throttle (channelId, count) ->
  await @$root.apiRequest 'GET', '/youtube/v3/search',
    maxResults: @count or 20
    part: 'snippet'
    channelId: @channelId
    order: 'date'
    type: 'video'
, 10000

Vue.component 'video-list',
  template: '#video-list'

  props: [ 'channelId', 'count' ]

  data: ->
    videos: []
    watched: {}

  mounted: ->
    @videos = await getVideosInChannel @channelId, @count

app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []
    order: []
    headers: [
      { value: 'index', text: 'Order', sort: @sortIndex, width: 5 }
      { value: 'title', text: 'Channel Name' }
      { value: 'videos', text: 'Videos', sortable: false }
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
        part: 'snippet'
        maxResults: 50

      @channels = resp.items.map (item, index) =>
        channelId = item.snippet.resourceId.channelId # NOT item.snippet.channelId
        if @order.length
          index = @order.indexOf(channelId)
          index = if index >= 0 then index else resp.items.length
        return {
          ..._.pick item.snippet, ['title', 'publishedAt']
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
      if newIndex
        item.index = newIndex
        app.writeStorage()
    , 500
