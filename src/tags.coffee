Vue.use VueYouTubeEmbed

Vue.component 'channel',
  template: '#channel'
  props: [ 'channel' ]
  data: ->
    newTag: null
  watch:
    newTag: ->
      @$root.addTag(@channel.channelId, @newTag)
      @$nextTick => @newTag = null

Vue.component 'videos',
  template: '#videos'

  props: [ 'tag' ]

  data: ->
    channels: []
    videos: []

  created: ->
    @channels = _(@$root.tags)
      .map (tags, channelId) =>
        if tags.includes(@tag) then channelId else null
      .filter Boolean
      .map (id) =>
        @$root.channels.find (c) -> c.channelId is id
      .value()
    
    for c in @channels
      resp = await @$root.apiRequest 'GET', "/youtube/v3/activities?channelId=#{c.channelId}",
        maxResults: 50
        part: 'snippet,contentDetails'

      vids = resp.items
        .filter (a) -> a.snippet.type is 'upload'
        .map (a) =>
          videoId = a.contentDetails.upload.videoId
          return {
            ..._.pick a.snippet, ['publishedAt', 'title']
            videoId: videoId
            showing: false
            watched: @$root.watched[videoId]?
          }
        .filter (v) -> not v.watched
        .slice 0, 5

      @videos.push ...vids

  computed:
    filteredVideos: ->
      _(@videos)
        .filter (v) =>
          not v.watched
        .sortBy ['publishedAt']
        .reverse()
        .value()

  methods:
    markWatched: (video) ->
      @$root.markWatched(video)
      video.watched = true
      video.showing = false

  filters:
    dateNice: (d) -> moment(d).format('ddd MMM D h:mma')
    dateHuman: (d) -> moment(d).fromNow()      

app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []
    tags: {}
    viewTag: null
    watched: {}

  mixins: [ window.goog ]

  created: ->
    await @signIn()
    @readStorage()

  computed:
    allTags: ->
      _(@tags)
        .values()
        .flattenDeep()
        .union()
        .uniq()
        .sortBy (t) -> t.toLowerCase()
        .value()

  methods:
    getChannels: ->
      resp = await @apiRequest 'GET', '/youtube/v3/subscriptions',
        mine: true
        part: 'snippet'
        maxResults: 50

      @channels = resp.items.map (item, index) =>
        channelId = item.snippet.resourceId.channelId # NOT item.snippet.channelId
        @tags[channelId] = [] unless @tags[channelId]
        return {
          ..._.pick item.snippet, ['title', 'publishedAt']
          channelId
        }

    readStorage: ->
      try
        state = JSON.parse localStorage.getItem 'yt-subs'
        @tags = state.tags if _.size(state.tags)
        if _.size(state.watched)
          @watched = _.fromPairs _.map(state.watched, (id) -> [id, 1])

    writeStorage: ->
      localStorage.setItem 'yt-subs', JSON.stringify
        tags: @tags
        watched: _.keys @watched

    addTag: (channelId, newTag) ->
      if newTag and not @tags[channelId].find (t) -> t is newTag
        @tags[channelId].push newTag
      @writeStorage()

    removeTag: (channelId, tag) ->
      @tags[channelId] = @tags[channelId].filter (t) -> t isnt tag
      @writeStorage()

    markWatched: (video) ->
      @watched[video.videoId] = 1
      @writeStorage()
