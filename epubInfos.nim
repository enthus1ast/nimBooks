## extracts some infos from an epub
import zip/zipfiles, streams, xmlparser, xmltree, options, strutils, strtabs, ospaths
type
  Epub = ZipArchive
  EpubInfo = object
    title: string
    creator: string
    publisher: string
    date: string
    subject: string
    language: string
    coverImage: string

proc openEpub*(path: string): Option[ZipArchive] =
  if not path.endsWith("epub"): return
  var epub: ZipArchive
  if not epub.open(path): return
  else: return some[ZipArchive](epub)

template firstOrEmpty(se: auto): auto = 
  if se.len > 0:
    se[0].innerText
  else:
    ""

proc extractInfo(epub: var Epub): EpubInfo = 
  result = EpubInfo()
  var fs = epub.getStream("OEBPS/content.opf")  
  let contentRaw = fs.readAll()
  let contentXml = contentRaw.parseXml()
  result.creator = contentXml.findAll("dc:creator").firstOrEmpty
  result.title = contentXml.findAll("dc:title").firstOrEmpty
  result.publisher = contentXml.findAll("dc:publisher").firstOrEmpty
  result.subject = contentXml.findAll("dc:subject").firstOrEmpty
  result.language = contentXml.findAll("dc:language").firstOrEmpty
  result.date = contentXml.findAll("dc:date").firstOrEmpty
  for elem in contentXml.findAll("meta"):
    var tags = elem.attrs()
    if tags.isNil: continue
    if not tags.hasKey("name"): continue
    if not (tags["name"] == "cover"): continue
    if not tags.hasKey("content"): continue
    result.coverImage = tags["content"]

proc get*(epub: var Epub, path: string): string = 
  var stream = epub.getStream(path)
  if stream.isNil: 
    # return ""
    raise newException(ValueError, "404") 
  stream.readAll()

proc extractCoverImage(epub: var Epub, path: string): string = 
  var fs = epub.getStream("OEBPS/images/" / path)
  return fs.readAll()

when isMainModule:
  var epubOpt = openEpub("./test/t01.epub")
  if isNone epubOpt:
    echo "could not open epub"
  var epub = epubOpt.get()
  let info = epub.extractInfo
  echo info
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