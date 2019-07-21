import strutils, tables, intsets
type 
  Books* = seq[string]
  Index = Table[string, IntSet]
  BookSearch* = object of RootObj
    books: Books
    index: Index

proc tokenize(str: string): seq[string] = 
  var cur = str.multiReplace({
    ",": " ",
    "[": " ",
    "]": " ", 
    "/": " ",
    "-": " ",
    ".": " "
  }).toLower()
  for token in splitWhitespace(cur):
    if token.strip() == "": continue
    result.add token


proc makeIndex(books: Books): Index = 
  for idx, book in books.pairs:
    var tokens = tokenize(book)
    for token in tokens:
      if not result.hasKey(token):
        result[token] = initIntSet()
      result[token].incl idx

proc update(path: string): Books =
  # result = @[]
  for line in lines(path):
    # echo tokens(line)
    result.add line

proc search(books: Books, index: Index, str: string): Books =
  # new and fast
  var founds: seq[IntSet] = @[]
  var foundSet: IntSet
  var tokens = str.tokenize()
  for token in tokens:
    if index.hasKey(token):
      founds.add index[token]
  if founds.len == 0:
    return @[]
  foundSet = founds[0]

  for idx in founds:
    foundSet = foundSet.intersection(idx)  
  for idx in foundSet:
    result.add books[idx]

proc search*(bookSearch: BookSearch, str: string): Books = 
  return search(bookSearch.books, bookSearch.index, str)

proc find(books: Books, str: string): Books =
  # old and slow
  for book in books:
    if book.toLower.contains(str.toLower()):
      result.add book

proc newBookSearch*(books: Books): BookSearch = 
  result = BookSearch()
  result.books = books
  result.index = makeIndex(result.books)

proc newBookSearch*(path: string = "BOOKS.txt"): BookSearch = 
  result = newBookSearch(update(path))

when isMainModule:
  import unittest
  const b1 = "/foo/baa/baz.epub"
  const b2 = "/foo/ööö"
  test "tokenize":
    check b1.tokenize() == @["foo", "baa", "baz", "epub"]
    check "".tokenize.len == 0
    check "foo baa".tokenize() == @["foo", "baa"]
    check "foo          baa".tokenize() == @["foo", "baa"]

  test "search":
    var books: Books = @[b1, b2]
    var bs = newBookSearch(books)
    check bs.search("foo") == @[b1, b2]
    check bs.search("baz") == @[b1]
    check bs.search("baz baz") == @[b1]
    check bs.search("baz baz baz") == @[b1]
    check bs.search("baz baz baz epup") == @[b1]

# import times
# proc findLoop() = 
#   while true:
#     var line = stdin.readLine()
    
#     var start = epochTime()
#     echo books.search(index, line)
#     echo epochTime() - start

#     # start = epochTime()
#     # echo "##: ", books.find(line)
#     # echo epochTime() - start

#     echo getOccupiedMem() / 1024 / 1024

# when isMainModule:
#   findLoop()