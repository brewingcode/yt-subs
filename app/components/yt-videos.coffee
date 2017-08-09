import Ember from 'ember'
import { task } from 'ember-concurrency'
import pr from 'npm:bluebird'
import moment from 'npm:moment'
import { storageFor } from 'ember-local-storage'
import config from '../config/environment'

log = (args...) ->
  if config.environment isnt 'production'
    console.log args...

export default Ember.Component.extend
  settings: storageFor('yt-subs-settings')
  googleApi: Ember.inject.service()

  init: (args...) ->
    @_super args...
    @get('load').perform()

  isRecent: (m) ->
    m = m.clone()
    m.add(@get('settings.recent'), 'hours').isAfter()

  load: task ->
    resp = yield do =>
      @get('googleApi').buildApiRequest 'GET', '/youtube/v3/subscriptions',
        mine: true
        part: 'snippet,contentDetails'
        maxResults: 50
      , null

    @set 'channels', Ember.Object.create()
    order = @get 'settings.order'
    log "loaded #{order.length} channels from settings.order: ", order

    resp.items.forEach (c) =>
      id =  c.snippet.resourceId.channelId
      @set "channels.#{id}",
        self: c
        id: id
        videos: []
      if order.indexOf(id) is -1
        order.push id

    @set 'settings.order', order

    resp = yield do =>
      pr.map resp.items, (channel) =>
        @get('googleApi').buildApiRequest 'GET', '/youtube/v3/search',
          maxResults: 20
          part: 'snippet'
          channelId: channel.snippet.resourceId.channelId
          order: 'date'
          type: 'video'
        , null
        .then (response) =>
          response.items.forEach (v) =>
            v.time = moment v.snippet.publishedAt
            v.timeAgo = v.time.fromNow()
            v.recent = @isRecent v.time
            @get("channels.#{v.snippet.channelId}.videos").pushObject v
      .catch console.error

  sortedChannels: Ember.computed 'channels.[]', 'orderChanged', ->
    @get('settings.order').filter (id) =>
      @get("channels.#{id}")?
    .map (id) =>
      @get "channels.#{id}"

  videosUpdated: (cb) ->
    new pr (resolve) =>
      Ember.run.later this, ->
        @toggleProperty 'orderChanged'
        resolve()
    .then cb

  changeRank: task (channelId, val) ->
    log 'changeRank:', @get("channels.#{channelId}.self.snippet.title"), val
    if not val
      log 'no val, abort change'
      return

    order = @get 'settings.order'
    val = val - 1
    if val < 0
      val = 0
    if val >= order.length
      val = order.length - 1
    old = order.indexOf channelId
    if val is old
      log 'no change, abort change'
      return

    order.splice val, 0, order.splice(old, 1)[0]
    @set 'settings.order', order
    yield @videosUpdated =>
      Ember.run.later this, -> $('#'+channelId+' input').focus()
  .drop()

  changeRecent: task (val) ->
    for _, c of @get 'channels'
      if videos = Ember.get c, 'videos'
        for v in videos
          Ember.set v, 'recent', @isRecent(v.time)
    yield @videosUpdated -> 0
  .drop()
