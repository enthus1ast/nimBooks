import epubInfos, options
import asynchttpserver, asyncdispatch, uri, json, ospaths
import xmlparser, xmltree, templates, strutils

var epub = openEpub("test/t01.epub")
epub.extractToc()

proc extendWithMain(content: string, title: string = "", toc: string = ""): string = tmpli html"""
      <html>
      <head>
        <meta charset="utf-8"/>
        <title>$title</title>
      </head>
      <body>
          <h1>$title</h1>
          
          <div id="toc" style="float: right;">
            $toc
          </div>

          <div id="content" style="max-width: 600px;">
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
  result.add "<ul>"
  for entry in epub.toc:
    # result.add "foo"
    result.add renderEntry(entry)
  result.add "</ul>"

# proc renderToc(toc: string): string = 
#   var xml = parseXml(toc)
#   let guide = xml.child("guide")
#   var content = ""
#   # content = "<html><body><head></head>"
#   content.add("<ul>")
#   for capitle in guide.items:
#     let lnk = """<a href="$#">$#</a>""" % [$capitle.attr("href"), $capitle.attr("href")]
#     content.add("<li>" & lnk &  "</li>")
#   content.add("</ul>")
#   result = content

var server = newAsyncHttpServer()
proc cb(req: Request) {.async, gcsafe.} =
  echo req.url
  if req.url.path == "/":
    # let ret = renderToc(epub.get("OEBPS/content.opf"))
    let ret = epub.renderToc()
    await req.respond(Http200, ret.extendWithMain("Table of content"))
  else:
    try:
      if req.url.path.endsWith("html"):
        # await req.respond(Http200, epub.get("OEBPS/" / req.url.path).extendWithMain(req.url.path, toc = renderToc(epub.get("OEBPS/content.opf"))))
        await req.respond(Http200, epub.get("OEBPS/" / req.url.path).extendWithMain(req.url.path, toc = epub.renderToc()))
        return
      else:  
        await req.respond(Http200, epub.get("OEBPS/" / req.url.path))
        return
    except:
      await req.respond(Http404, "404 not found")

waitFor server.serve(Port(8976), cb)