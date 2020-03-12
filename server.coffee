express = require 'express'
http = require 'http'
fs = require 'fs'
cors = require 'cors'

app = express()

port = process.env.PORT or 3000
host = process.env.HOST or '127.0.0.1'

app.use express.static 'dist'

checkCors = cors
  origin: (origin, cb) ->
    if ['http://localhost:3000', 'https://yt.brewingcode.net'].includes origin
      cb null, true
    else
      cb new Error 'Not allowed by cors'

app.post '/state', checkCors, (req, res) ->
  if req.d
  res.send status:'ok'

server = http.createServer(app)
server.listen port, host, ->
  console.log "listening on #{host}:#{port}"

process.on 'SIGTERM', ->
  console.log 'closing down server.coffee'
  server.close()

