## walks the filesystem and generates BOOKS.txt
import os, strutils

proc genBooks*(path: string, booksTxt = "BOOKS.txt") =
  ## walks `path` generates text file with all books at `booksTxt`
  var booksFile = open(booksTxt, fmWrite)
  echo "walking: ", path
  for bookPath in walkDirRec(path, relative = true):
    if not bookPath.endsWith(".epub"):
      echo "skipping file: ", bookPath
      continue
    echo bookPath
    booksFile.write(bookPath & "\n")
  booksFile.flushFile
  booksFile.close()

when isMainModule:
  const path = """books"""
  genBooks(path)
