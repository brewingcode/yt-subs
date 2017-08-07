import Ember from 'ember'
import { task } from 'ember-concurrency'
import pr from 'npm:bluebird'
import moment from 'npm:moment'

export default Ember.Component.extend
  videosPerChannel: 5

  init: (args...) ->
    @_super args...
    @get('load').perform()

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
