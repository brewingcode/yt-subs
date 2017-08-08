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
          @auth.isSignedIn.listen @updateSigninStatus
          # Handle initial sign-in state. (Determine if user is already signed in.)
          user = @auth.currentUser.get()
          @setSigninStatus()
          # Call handleAuthClick function when user clicks on
          #      "Sign In/Authorize" button.
          $('#sign-in-or-out-button').click => @handleAuthClick()
          $('#revoke-access-button').click => @revokeAccess()

  handleAuthClick: ->
    if @auth.isSignedIn.get()
      # User is authorized and has clicked 'Sign out' button.
      @auth.signOut()
    else
      # User is not signed in. Start Google auth flow.
      @auth.signIn()

  revokeAccess: ->
    @auth.disconnect()

  setSigninStatus: (isSignedIn) ->
    user = @auth.currentUser.get()
    isAuthorized = user.hasGrantedScopes @scope
    if isAuthorized
      $('#sign-in-or-out-button').html 'Sign out'
      $('#revoke-access-button').css 'display', 'inline-block'
      $('#auth-status').html 'You are currently signed in and have granted ' + 'access to this app.'
    else
      $('#sign-in-or-out-button').html 'Sign In/Authorize'
      $('#revoke-access-button').css 'display', 'none'
      $('#auth-status').html 'You have not authorized this app or you are ' + 'signed out.'

  updateSigninStatus: (isSignedIn) ->
    @setSigninStatus()
    window.location.reload()

  createResource: (properties) ->
    resource = {}
    normalizedProps = properties
    for p of properties
      value = properties[p]
      if p and p.substr(-2, 2) == '[]'
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
          if pa == propArray.length - 1
            ref[key] = normalizedProps[p]
          else
            ref = ref[key] = ref[key] or {}
          pa++
    resource

  removeEmptyParams: (params) ->
    for p of params
      if !params[p] or params[p] == 'undefined'
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
