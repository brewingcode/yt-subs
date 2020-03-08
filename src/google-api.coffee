window.goog =
  data: ->
    auth: null
    authorized: false
    gerror: null
    scope: 'https://www.googleapis.com/auth/youtube.readonly'

  created: ->
    window.gapi.load 'client:auth2',
      callback: =>
        # Retrieve the discovery document for version 3 of YouTube Data API.
        # In practice, your app can retrieve one or more discovery documents.
        discoveryUrl = 'https://www.googleapis.com/discovery/v1/apis/youtube/v3/rest'
        # Initialize the gapi.client object, which app uses to make API requests.
        # Get API key and client ID from API Console.
        # 'scope' field specifies space-delimited list of access scopes.
        window.gapi.client.init
          discoveryDocs: [ discoveryUrl ]
          clientId: '11548176621-dneqrbb90krp9nl010cfib18uelggre4.apps.googleusercontent.com'
          scope: @scope
        .then =>
          @auth = window.gapi.auth2.getAuthInstance()
          # Listen for sign-in state changes.
          @auth.isSignedIn.listen => @updateSigninStatus()
          @setSigninStatus()
        , (err) =>
          console.error 'gapi init error: ', err
          @gerror = "Google API failed to initialize: #{err.details}"
      onerror: ->
        console.error 'gapi error'
        @gerror = 'Google API failed to load'

  methods:
    signOut: ->
      @auth.signOut()
      @authorized = false

    signIn: ->
      @auth?.signIn().then =>
        @setSigninStatus()

    revoke: ->
      @auth.disconnect()
      @authorized = false

    setSigninStatus: (isSignedIn) ->
      user = @auth.currentUser.get()
      @authorized = user?.hasGrantedScopes @scope
      @email = user?.getBasicProfile()?.getEmail()
      if @email
        @getChannels()

    updateSigninStatus: (isSignedIn) ->
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

    # async
    apiRequest: (requestMethod, path, params, properties) ->
      params = @removeEmptyParams(params)
      if properties
        resource = @createResource(properties)
        req = window.gapi.client.request(
          'body': resource
          'method': requestMethod
          'path': path
          'params': params)
      else
        req = window.gapi.client.request(
          'method': requestMethod
          'path': path
          'params': params)

      new Promise (resolve) ->
        req.execute(resolve)
