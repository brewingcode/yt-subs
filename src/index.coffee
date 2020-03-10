Vue.use VueYouTubeEmbed

Vue.component 'channel',
  template: '#channel'
  props: [ 'channel' ]
  data: ->
    newTag: null
  watch:
    newTag: ->
      @$root.addTag(@channel.channelId, @newTag)
      @$nextTick =>
        @newTag = null
        @$refs.combobox.blur()

Vue.component 'videos',
  template: '#videos'

  props: [ 'tag' ]

  data: ->
    channels: []
    videos: []
    videosPerChannel: 5
    players: []

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
            channelId: c.channelId
            showing: false
            watched: @$root.watched[videoId]?
            smallthumb: a.snippet.thumbnails.default
            bigthumb: a.snippet.thumbnails.high
          }

      @videos.push ...vids

  computed:
    centerOnSmall: ->
      'text-align': if @$vuetify.breakpoint.smAndDown then 'center' else 'inherit'
      'justify-content': if @$vuetify.breakpoint.smAndDown then 'center' else 'left'

    filteredVideos: ->
      perChannel = {}

      _(@videos)
        .filter (v) ->
          not v.watched
        .filter (v) =>
          perChannel[v.channelId] ||= 0
          perChannel[v.channelId]++ < @videosPerChannel
        .sortBy ['publishedAt']
        .reverse()
        .value()

  methods:
    markWatched: (video) ->
      @$root.markWatched(video)
      video.watched = true
      video.showing = false

    playerReady: (e) ->
      @players.push e.target

    dismissed: -> 
      @players.forEach (p) -> p.pauseVideo()

    stop: (v) ->
      v.showing = false
      @players.forEach (p) -> p.pauseVideo()

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
        @$set(@tags, channelId, []) unless @tags[channelId]
        return {
          ..._.pick item.snippet, ['title', 'publishedAt']
          channelId
        }

    readStorage: ->
      try
        state = JSON.parse localStorage.getItem 'yt-subs'
        if _.size(state.tags)
          for k,v of state.tags
            @$set @tags, k, v
        if _.size(state.watched)
          @watched = _.fromPairs _.map(state.watched, (id) -> [id, 1])

    writeStorage: ->
      localStorage.setItem 'yt-subs', JSON.stringify
        tags: @tags
        watched: _.keys @watched

    addTag: (channelId, newTag) ->
      if newTag and not @tags[channelId].find (t) -> t is newTag
        tags = @tags[channelId]
        tags.push newTag
        @$set @tags, channelId, tags
      @writeStorage()

    removeTag: (channelId, tag) ->
      tags = @tags[channelId].filter (t) -> t isnt tag
      @$set @tags, channelId, tags
      @writeStorage()

    markWatched: (video) ->
      @watched[video.videoId] = 1
      @writeStorage()
