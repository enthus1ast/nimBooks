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
    title*: string
    creator*: string
    publisher*: string
    date*: string
    subject*: string
    language*: string
    coverImage*: string
    toc*: EpubToc

proc openEpub*(path: string): Epub =
  if not path.endsWith("epub"): return
  var epub: Epub
  if not epub.raw.open(path): return
  else: return epub

template firstOrEmpty(se: auto): auto = 
  if se.len > 0:
    se[0].innerText
  else:
    ""

proc extractInfo*(epub: var Epub) = 
  var fs = epub.raw.getStream("OEBPS/content.opf")  
  let contentRaw = fs.readAll()
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

proc get*(epub: var Epub, path: string): string = 
  var stream = epub.raw.getStream(path)
  if stream.isNil: 
    # return ""
    raise newException(ValueError, "404") 
  stream.readAll()

# proc extractCoverImage(epub: var Epub, path: string): string = 
#   return epub.get("OEBPS/images/" / path)

proc parseNavPoint(entry: XmlNode): TocEntry = 
  result.headerTag = entry.attr("class")
  result.label = entry.child("navLabel").innerText
  result.content = entry.child("content").attr("src")
  for subEntry in entry.findAll("navPoint"):
    result.subentries.add parseNavPoint(subEntry)

proc extractToc*(epub: var Epub) =
  let toc = epub.get("OEBPS/toc.ncx").parseXml()
  for entry in toc.child("navMap"):
    epub.toc.add parseNavPoint(entry)  

when isMainModule:
  var epub = openEpub("./test/t01.epub")
  epub.extractInfo()
  epub.extractToc()
  # if isNone epubOpt:
  #   echo "could not open epub"
  # var epub = epubOpt.get()
  # echo repr epub

  # let info = epub.extractInfo
  # echo info
  # writeFile("cover.jpg", epub.extractCoverImage(info.coverImage))

# echo epub.open("./test/t01.epub")
# var fs = epub.getStream("OEBPS/content.opf")
# let contentRaw = fs.readAll()
# let contentXml = contentRaw.parseXml()
# echo contentXml.findAll("dc:creator")[0].innerText


# <dc:title>Der Drachenbeinthron</dc:title>
# <dc:publisher>Klett-Cotta Verlag</dc:publisher>                                                             
# <dc:date>2010-12-26T23:00:00+00:00</dc:date>
# <dc:identifier id="PackageID">978-3-608-10149-2_Williams_DasGeheimnisdergrossenSchwerter1</dc:identifier>
# dc:subject
# dc:language