Vue.use(VueYouTubeEmbed)

Vue.component 'video-list',
  template: '#video-list'

  props: [ 'channelId', 'count' ]

  data: ->
    videos: []

  mounted: ->
    resp = await @$root.apiRequest 'GET', "/youtube/v3/activities?channelId=#{@channelId}",
      maxResults: 50
      part: 'snippet,contentDetails'
    @videos = resp.items
      .filter (a) -> a.snippet.type is 'upload'
      .map (a) ->
        return {
          ..._.pick a.snippet, ['publishedAt', 'title']
          videoId: a.contentDetails.upload.videoId
          showing: false
        }

    @filterVideos()

  filters:
    dateNice: (d) -> moment(d).format('ddd MMM D h:mma')
    dateHuman: (d) -> moment(d).fromNow()

  methods:
    filterVideos: ->
      @videos = @videos
        .filter (v) => not @$root.watched[v.videoId]
        .slice 0, @count or 5

    markWatched: (video) ->
      video.showing = false
      @$root.watched[video.videoId] = 1
      @$root.writeStorage()
      @filterVideos()

app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []
    order: []
    watched: {}
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
        @watched = state.watched if _.size(state.watched)

    writeStorage: ->
      localStorage.setItem 'yt-subs', JSON.stringify
        order: _.sortBy(@channels, 'index').map (c) -> c.channelId
        watched: @watched

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
