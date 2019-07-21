import bookSearch
import asynchttpserver, asyncdispatch, uri, json

var bs = newBookSearch()
var server = newAsyncHttpServer()
proc cb(req: Request) {.async, gcsafe.} =
  echo req.url
  let searchStr = try:
    req.url.query.decodeUrl()
  except:
    ""
  echo searchStr
  if searchStr == "": 
    await req.respond(Http200, readFile("index.html"))
    return
  let founds = bs.search(searchStr)
  await req.respond(Http200, $ %* founds)


waitFor server.serve(Port(8976), cb)