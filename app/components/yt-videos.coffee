import Ember from 'ember'

export default Ember.Component.extend
  channels: Ember.A()
  foo: 0
  init: (args...) ->
    @_super args...
    buildApiRequest 'GET', '/youtube/v3/subscriptions',
      mine: true
      part: 'snippet,contentDetails'
    , null, (resp) =>
      console.log resp.items
      resp.items.forEach (i) =>
        @get('channels').pushObject(i)
      @set 'foo', 1
      @notifyPropertyChange('channels')


