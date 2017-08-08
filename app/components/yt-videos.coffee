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

  load: task ->
    resp = yield do ->
      new pr (resolve) ->
        buildApiRequest 'GET', '/youtube/v3/subscriptions',
          mine: true
          part: 'snippet,contentDetails'
          maxResults: 50
        , null, resolve

    @set 'channels', Ember.Object.create()
    order = @get('channelOrder.byId')

    resp.items.forEach (c) =>
      id =  c.snippet.resourceId.channelId
      @set "channels.#{id}",
        self: c
        id: id
        timeAgo: moment(c.snippet.publishedAt).fromNow()
        videos: []
      if order.indexOf(id) is -1
        order.push id

    @set('channelOrder.byId', order)

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

  sortedChannels: Ember.computed 'channels.[]', 'orderChanged', ->
    if not @get('channels')
      return Ember.A()

    return @get('channelOrder.byId').map (id, i) =>
      @set("channels.#{id}.index", i + 1)
      return @get("channels.#{id}")

  actions:
    changeRank: (channelId, val) ->
      order = @get 'channelOrder.byId'
      val = val - 1
      if val < 0
        val = 0
      if val >= order.length
        val = order.length - 1
      old = order.indexOf channelId
      order.splice val, 0, order.splice(old, 1)[0]
      @set 'channelOrder.byId', order
      @toggleProperty 'orderChanged'

