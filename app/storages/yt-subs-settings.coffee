import StorageObject from 'ember-local-storage/local/object'

Storage = StorageObject.extend()

Storage.reopenClass
  initialState: ->
    order: []
    videosPerChannel: 5
    recent: 12

export default Storage
