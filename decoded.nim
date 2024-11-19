import nimcrypto, os, strutils, tables

proc decryptFile(encryptedPath: string, originalPath: string, key: string, iv: string): bool =
  try:
    var dctx: CBC[aes256]
    var encContent = readFile(encryptedPath)
    var decText = newString(encContent.len)
    var keyStr = newString(aes256.sizeKey)
    var ivStr = newString(aes256.sizeBlock)
    copyMem(addr keyStr[0], unsafeAddr key[0], min(len(key), aes256.sizeKey))
    copyMem(addr ivStr[0], unsafeAddr iv[0], min(len(iv), aes256.sizeBlock))
    dctx.init(keyStr, ivStr)
    dctx.decrypt(encContent, decText)
    dctx.clear()
    let paddingSize = decText[^1].ord
    if paddingSize > decText.len:
      echo "Invalid padding detected for file: ", encryptedPath
      return false
    decText.setLen(decText.len - paddingSize)
    writeFile(originalPath, decText)
    echo "File decrypted successfully: ", originalPath
    removeFile(encryptedPath)
    echo "Encrypted file removed: ", encryptedPath
    return true
  except:
    echo "Error decrypting file: ", encryptedPath
    echo "Error message: ", getCurrentExceptionMsg()
    return false

proc readMappingFile(mapFilePath: string): Table[string, string] =
  var mapping: Table[string, string]
  for line in lines(mapFilePath):
    let parts = line.split(" -> ")
    if parts.len == 2:
      mapping[parts[1].strip()] = parts[0].strip()
  return mapping

proc decryptFolder(mapping: Table[string, string]) =
  var filesDecrypted = 0
  var filesSkipped = 0
  var filesFailed = 0

  echo "Decrypting files based on mapping"

  for encryptedPath, originalPath in mapping.pairs:
    echo "Processing file: ", encryptedPath
    if fileExists(encryptedPath):
      let key = "dniwasdajdaoidjoiajsdoijo"
      let iv = "0123456789ABCDEF"
      if decryptFile(encryptedPath, originalPath, key, iv):
        inc(filesDecrypted)
      else:
        inc(filesFailed)
    else:
      echo "File not found: ", encryptedPath
      inc(filesSkipped)

  echo "Total files decrypted successfully: ", filesDecrypted
  echo "Total files skipped: ", filesSkipped
  echo "Total files failed to decrypt: ", filesFailed

let desktopPath = getEnv("USERPROFILE") & r"\Desktop"
let mapFilePath = desktopPath / "encrypt.txt"

if fileExists(mapFilePath):
  let mapping = readMappingFile(mapFilePath)
  decryptFolder(mapping)
else:
  echo "Mapping file not found: ", mapFilePath