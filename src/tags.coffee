Vue.component 'channel',
  template: '#channel'
  props: [
    'channel'
  ]
  data: ->
    newTag: null
  watch:
    newTag: ->
      @$root.addTag(@channel.channelId, @newTag)
      @$nextTick => @newTag = null

app = new Vue
  el: '#app'
  template:'#app'
  vuetify: new Vuetify()

  data: ->
    channels: []
    tags: {}

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

    writeStorage: ->
      localStorage.setItem 'yt-subs', JSON.stringify
        tags: @tags

    addTag: (channelId, newTag) ->
      if newTag and not @tags[channelId].find (t) -> t is newTag
        @tags[channelId].push newTag
      @writeStorage()
