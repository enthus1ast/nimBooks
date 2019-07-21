import epubInfos, options
import asynchttpserver, asyncdispatch, uri, json, ospaths, strutils
import xmlparser, xmltree, templates, strutils, os

var file = ""
if paramCount() > 0:
  file = paramStr(1)
#file = "test/t01.epub"
#file = "test/The_vision_of_hell._by_Dante_Alighieri.epub"
#file = "test/t02.epub"
#file = "test/Dracula_-_by_Bram_Stoker.epub"
#file = "test/The_Adventures_of_Sherlock_Holmes_-_by_Arthur_Conan_Doyle.epub"


echo "Opening: ", file
var epub = openEpub(file)
epub.extractToc()
epub.extractInfo()

proc extendWithMain(content: string, title: string = "", toc: string = ""): string = 
  tmplf "templates/master.html"

proc renderEntry(entry: TocEntry): string = 
  tmplf "templates/entry.html"

proc renderToc(epub: Epub): string = 
  tmplf "templates/toc.html"

proc renderInfo(epub: Epub): string = 
  tmplf "templates/info.html"

var server = newAsyncHttpServer()
proc cb(req: Request) {.async, gcsafe.} =
  echo req.url
  if req.url.path == "/":
    let ret = epub.renderInfo() & "<br>" & epub.renderToc()
    await req.respond(Http200, ret.extendWithMain("Table of content"))
  else:
    try:
      if req.url.path.endsWith("html") or req.url.path.endsWith("htm"):
        await req.respond(Http200, epub.get(epub.basePath / req.url.path.strip(chars = {'/'})).extendWithMain(req.url.path, toc = epub.renderToc()))
        return
      else:  
        await req.respond(Http200, epub.get(epub.basePath / req.url.path))
        return
    except:
      await req.respond(Http404, "404 not found")

waitFor server.serve(Port(8976), cb)