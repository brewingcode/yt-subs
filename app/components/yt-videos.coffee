import Ember from 'ember'
import { task } from 'ember-concurrency'

export default Ember.Component.extend
  init: (args...) ->
    @_super args...
    @get('load').perform()

  load: task ->
    resp = yield do ->
      new Ember.RSVP.Promise (resolve) ->
        buildApiRequest 'GET', '/youtube/v3/subscriptions',
          mine: true
          part: 'snippet,contentDetails'
        , null, resolve
    @set 'channels', resp.items
