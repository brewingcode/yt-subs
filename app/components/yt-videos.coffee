import Ember from 'ember'
import { task } from 'ember-concurrency'
import pr from 'npm:bluebird'
import moment from 'npm:moment'
import { storageFor } from 'ember-local-storage'

export default Ember.Component.extend
  videosPerChannel: 5
  channelOrder: storageFor('channelOrder')

  init: (args...) ->
    @_super args...
    @get('load').perform()

  rank: (id) ->
    return @get("channelOrder.#{id}") or moment(@get("channels.#{id}.self.snippet.publishedAt")).unix()

  load: task ->
    resp = yield do ->
      new pr (resolve) ->
        buildApiRequest 'GET', '/youtube/v3/subscriptions',
          mine: true
          part: 'snippet,contentDetails'
          maxResults: 50
        , null, resolve

    @set 'channels', Ember.Object.create()
    resp.items.forEach (c) => @set "channels.#{c.snippet.resourceId.channelId}",
      self: c
      timeAgo: moment(c.snippet.publishedAt).fromNow()
      rank: @rank(c.snippet.publishedAt)
      videos: []

    resp = yield do =>
      pr.map resp.items, (channel) =>
        new pr (resolve) =>
          buildApiRequest 'GET', '/youtube/v3/search',
            maxResults: 20
            part: 'snippet'
            channelId: channel.snippet.resourceId.channelId
            order: 'date'
          , null, (response) =>
            response.items.forEach (v) =>
              v.timeAgo = moment(v.snippet.publishedAt).fromNow()
              @get("channels.#{v.snippet.channelId}.videos").pushObject v
            resolve()
      .catch console.error

  sortedChannels: Ember.computed 'channels.[]', ->
    if not @get('channels')
      return Ember.A()

    ids = Object.keys @get('channels')

    ids.sort (a,b) =>
      aRank = @rank(a)
      bRank = @rank(b)
      return switch
        when aRank < bRank then 1
        when aRank == bRank then 0
        when aRank > bRank then -1

    return Ember.A ids.map (id, i) =>
      channel = @get("channels.#{id}")
      channel.index = i + 1
      return channel

