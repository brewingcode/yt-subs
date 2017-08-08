import Ember from 'ember'
import injectScript from 'ember-inject-script'

export default Ember.Service.extend
  scope: 'https://www.googleapis.com/auth/youtube.readonly'

  init: (args...) ->
    @_super args...
    injectScript('https://apis.google.com/js/api.js').then =>
      window.gapi.load 'client:auth2', =>
        # Retrieve the discovery document for version 3 of YouTube Data API.
        # In practice, your app can retrieve one or more discovery documents.
        discoveryUrl = 'https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest'
        # Initialize the gapi.client object, which app uses to make API requests.
        # Get API key and client ID from API Console.
        # 'scope' field specifies space-delimited list of access scopes.
        window.gapi.client.init
          apiKey: 'AIzaSyCOzVWc5epKJ0kf5QSUNtZCx9diYwTDt68'
          discoveryDocs: [ discoveryUrl ]
          clientId: '26306428056-qfc1r2rsamlosjl6lvf2h0hf2oepg7hh.apps.googleusercontent.com'
          scope: @scope
        .then =>
          @auth = window.gapi.auth2.getAuthInstance()
          # Listen for sign-in state changes.
          @auth.isSignedIn.listen => @updateSigninStatus()
          # Handle initial sign-in state. (Determine if user is already signed in.)
          @setSigninStatus()

  signOut: ->
    @auth.signOut()
    @set 'authorized', false

  signIn: ->
    @auth.signIn().then =>
      @setSigninStatus()

  revoke: ->
    @auth.disconnect()
    @set 'authorized', false

  setSigninStatus: (isSignedIn) ->
    user = @auth.currentUser.get()
    @setProperties
      authorized: user.hasGrantedScopes @scope
      ready: true

  updateSigninStatus: (isSignedIn) ->
    console.log 'updateSigninStatus'
    @setSigninStatus(isSignedIn)

  createResource: (properties) ->
    resource = {}
    normalizedProps = properties
    for p of properties
      value = properties[p]
      if p and p.substr(-2, 2) is '[]'
        adjustedName = p.replace('[]', '')
        if value
          normalizedProps[adjustedName] = value.split(',')
        delete normalizedProps[p]
    for p of normalizedProps
      # Leave properties that don't have values out of inserted resource.
      if normalizedProps.hasOwnProperty(p) and normalizedProps[p]
        propArray = p.split('.')
        ref = resource
        pa = 0
        while pa < propArray.length
          key = propArray[pa]
          if pa is propArray.length - 1
            ref[key] = normalizedProps[p]
          else
            ref = ref[key] = ref[key] or {}
          pa++
    resource

  removeEmptyParams: (params) ->
    for p of params
      if !params[p] or params[p] is 'undefined'
        delete params[p]
    params

  executeRequest: (request, cb) ->
    request.execute cb

  buildApiRequest: (requestMethod, path, params, properties, cb) ->
    ready = setInterval =>
      if @auth
        clearInterval ready
      else
        return

      params = @removeEmptyParams(params)
      request = undefined
      if properties
        resource = @createResource(properties)
        request = window.gapi.client.request(
          'body': resource
          'method': requestMethod
          'path': path
          'params': params)
      else
        request = window.gapi.client.request(
          'method': requestMethod
          'path': path
          'params': params)
      @executeRequest request, cb
    , 100
