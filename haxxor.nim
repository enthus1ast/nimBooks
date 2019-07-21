import epubInfos, options
import asynchttpserver, asyncdispatch, uri, json, ospaths, strutils
import xmlparser, xmltree, templates, strutils

var epub = openEpub("test/t01.epub")
# var epub = openEpub("test/The_vision_of_hell._by_Dante_Alighieri.epub")
# var epub = openEpub("test/t02.epub")
# var epub = openEpub("test/Dracula_-_by_Bram_Stoker.epub")
# var epub = openEpub("test/The_Adventures_of_Sherlock_Holmes_-_by_Arthur_Conan_Doyle.epub")
epub.extractToc()
epub.extractInfo()

proc extendWithMain(content: string, title: string = "", toc: string = ""): string = tmpli html"""
      <html>
      <head>
        <meta charset="utf-8"/>
        <title>$title</title>
      </head>

      <style>
        #toc {
          float: right;
          overflow: scroll;
          position: fixed;
          right: 0px;
          height: 100%;
          max-width: 500px;
        }
        #content {
          max-width: 600px;
        }
        #bookInfo table {
          border: solid
        }       
      </style>

      <body>
          <small>$title</small>
          
          <div id="toc">
            $toc
          </div>

          <div id="content">
            $content
          </div>
      </body>
      </html>
    """

proc renderEntry(entry: TocEntry): string = tmpli """
    <li><a href="$(entry.content)" class="$(entry.headerTag)">$(entry.label)</a></$(entry.headerTag)></li>
    <ul>
    $for subentry in entry.subentries {
      $(renderEntry(subentry))
    }
    </ul>
  """

proc renderToc(epub: Epub): string = 
  result = ""
  result.add "<i>" & epub.creator & "</i><br>"
  result.add "<strong>" & epub.title & "</strong><br>"
  result.add "<ul>"
  for entry in epub.toc:
    # result.add "foo"
    result.add renderEntry(entry)
  result.add "</ul>"

proc renderInfo(epub: Epub): string = tmpli """
    <div id="bookInfo">
      <strong>Info:</strong>
      <table>
      <tr>
        <td>title</td>
        <td>$(epub.title)</td>
      </tr>
      <tr>
        <td>creator</td>
        <td>$(epub.creator)</td>
      </tr>
      <tr>
        <td>publisher</td>
        <td>$(epub.publisher)</td>
      </tr>
      <tr>
        <td>date</td>
        <td>$(epub.date)</td>
      </tr>
      <tr>
        <td>subject</td>
        <td>$(epub.subject)</td>
      </tr>
      <tr>
        <td>language</td>
        <td>$(epub.language)</td>
      </tr>
      </table>
    </div>
  """

var server = newAsyncHttpServer()
proc cb(req: Request) {.async, gcsafe.} =
  echo req.url
  if req.url.path == "/":
    let ret = epub.renderInfo() & "<br>" & epub.renderToc()
    await req.respond(Http200, ret.extendWithMain("Table of content"))
  else:
    try:
      if req.url.path.endsWith("html"):
        await req.respond(Http200, epub.get(epub.basePath / req.url.path.strip(chars = {'/'})).extendWithMain(req.url.path, toc = epub.renderToc()))
        return
      else:  
        await req.respond(Http200, epub.get(epub.basePath / req.url.path))
        return
    except:
      await req.respond(Http404, "404 not found")

waitFor server.serve(Port(8976), cb)