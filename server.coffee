express = require 'express'
http = require 'http'
fs = require 'fs'
cors = require 'cors'

app = express()

port = process.env.PORT or 3000
host = process.env.HOST or '127.0.0.1'
dataDir = __dirname + '/data'
if not fs.existsSync dataDir
  fs.mkdirSync dataDir

app.use express.static 'dist'

checkCors = do ->
  origins = [
    'http://localhost:3000'
    'http://localhost:3002'
    'https://yt.brewingcode.net'
  ]

  return cors
    origin: (origin, cb) ->
      if origins.includes origin
        cb null, true
      else
        cb new Error 'Not allowed by cors'

app.post '/state', express.json(), checkCors, (req, res) ->
  { gid } = req.body
  if req.body?.set
    fs.writeFileSync "#{dataDir}/#{gid}.json", JSON.stringify req.body.set
    res.send {}
  else
    try
      res.send JSON.parse fs.readFileSync "#{dataDir}/#{gid}.json"
    catch e
      res.send {}

server = http.createServer(app)
server.listen port, host, ->
  console.log "listening on #{host}:#{port}"

process.on 'SIGTERM', ->
  console.log 'closing down server.coffee'
  server.close()
