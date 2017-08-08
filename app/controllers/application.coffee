import Ember from 'ember'

export default Ember.Controller.extend
  googleApi: Ember.inject.service()
  actions:
    signIn: -> @get('googleApi').signIn()
    signOut: -> @get('googleApi').signOut()
    revoke: -> @get('googleApi').revoke()
