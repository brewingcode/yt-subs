import Ember from 'ember'
import { task } from 'ember-concurrency'
import pr from 'npm:bluebird'

export default Ember.Component.extend
  init: (args...) ->
    @_super args...
    @get('load').perform()

  load: task ->
    resp = yield do ->
      new pr (resolve) ->
        buildApiRequest 'GET', '/youtube/v3/subscriptions',
          mine: true
          part: 'snippet,contentDetails'
        , null, resolve
    @set 'channels', resp.items
