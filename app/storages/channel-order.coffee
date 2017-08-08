import StorageObject from 'ember-local-storage/local/object'

Storage = StorageObject.extend()

Storage.reopenClass
  initialState: ->
    byId: []

export default Storage
