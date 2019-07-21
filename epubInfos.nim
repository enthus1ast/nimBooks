## extracts some infos from an epub
import zip/zipfiles, streams, xmlparser, xmltree, options, strutils, strtabs, ospaths, tables
type
  TocEntry* = object
    label*: string
    content*: string
    headerTag*: string
    subentries*: EpubToc
  EpubToc* = seq[TocEntry]
  Epub* = object
    raw: ZipArchive
    contentPath: string
    basePath*: string 
    title*: string
    creator*: string
    publisher*: string
    date*: string
    subject*: string
    language*: string
    coverImage*: string
    toc*: EpubToc

proc get*(epub: var Epub, path: string): string = 
  var stream = epub.raw.getStream(path)
  if stream.isNil: 
    # return ""
    raise newException(ValueError, "not found: " & path) 
  stream.readAll()

proc extractContentPath(epub: var Epub) = 
  epub.contentPath = epub.get("META-INF/container.xml").parseXml.findAll("rootfile")[0].attr("full-path")
  if epub.contentPath.contains("/"):
    epub.basePath = epub.contentPath.split("/")[0]
  else:
    epub.basePath = ""
  # if basePath == "":
    # basePath = "/"
  # epub.basePath = 
  echo "Base Path:" , epub.basePath

proc openEpub*(path: string): Epub =
  if not path.endsWith("epub"): return
  var epub: Epub
  if not epub.raw.open(path): return
  else: 
    epub.extractContentPath()
    return epub

template firstOrEmpty(se: auto): auto = 
  if se.len > 0:
    se[0].innerText
  else:
    ""

proc extractInfo*(epub: var Epub) = 
  let contentRaw = epub.get(epub.contentPath)
  let contentXml = contentRaw.parseXml()
  epub.creator = contentXml.findAll("dc:creator").firstOrEmpty
  epub.title = contentXml.findAll("dc:title").firstOrEmpty
  epub.publisher = contentXml.findAll("dc:publisher").firstOrEmpty
  epub.subject = contentXml.findAll("dc:subject").firstOrEmpty
  epub.language = contentXml.findAll("dc:language").firstOrEmpty
  epub.date = contentXml.findAll("dc:date").firstOrEmpty
  for elem in contentXml.findAll("meta"):
    var tags = elem.attrs()
    if tags.isNil: continue
    if not tags.hasKey("name"): continue
    if not (tags["name"] == "cover"): continue
    if not tags.hasKey("content"): continue
    epub.coverImage = tags["content"]

# proc extractCoverImage(epub: var Epub, path: string): string = 
#   return epub.get("OEBPS/images/" / path)

proc parseNavPoint(entry: XmlNode): TocEntry = 
  result.headerTag = entry.attr("class")
  result.label = entry.child("navLabel").innerText
  result.content = entry.child("content").attr("src")
  for subEntry in entry.findAll("navPoint"):
    result.subentries.add parseNavPoint(subEntry)

proc extractToc*(epub: var Epub) =
  let toc = epub.get( epub.basePath / "toc.ncx").parseXml()
  for entry in toc.child("navMap"):
    epub.toc.add parseNavPoint(entry)  

when isMainModule:
  var epub = openEpub("./test/t01.epub")
  epub.extractInfo()
  epub.extractToc()
