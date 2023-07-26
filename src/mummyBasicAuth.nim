import mummy, mummy/routers
import webby/httpheaders, strutils, base64, strformat, parseutils

type
  TestBasicAuth* = proc(user, pass: string): bool {.gcsafe.}


# proc splitBasicAuth(val: string): tuple[user, pass: string] =
#   # const basic = "Basic "
#   # if not
#   try:
#     let parts = val.split("Basic", 1)[1].decode().split(":")
#     # echo parts
#     if parts.len == 2:
#       return (parts[0], parts[1])
#     else:
#       return ("", "")
#   except:
#     return ("", "")
#
# proc splitBasicAuth2(val: string): tuple[user, pass: string] =
#   try:
#     const basic = "Basic "
#     if val.len <= basic.len: return
#     if not val.startsWith(basic): return
#     let parts = val[basic.len .. ^1].decode().split(":")
#     if parts.len != 2: return
#     return (parts[0], parts[1])
#   except:
#     return
#
proc splitBasicAuth3(val: string): tuple[user, pass: string] =
  try:
    const basic = "Basic "
    if val.len <= basic.len: return
    if not val.startsWith(basic): return
    let deco = val[basic.len .. ^1].decode()
    let pos = parseUntil(deco, result.user, ':',  0) + 1
    result.pass = deco[pos .. ^1]
  except:
    return

proc requiresAuth*(handler: RequestHandler, testProc: TestBasicAuth, realm = "Login", failureBody = "please log in", headers: HttpHeaders = emptyHttpHeaders()): RequestHandler =
 return proc (request: Request) =
    if "Authorization" in request.headers:
      let (user, pass) = splitBasicAuth3(request.headers["Authorization"])
      if testProc(user, pass):
        handler(request)
        return
    var headers: HttpHeaders = headers
    headers["WWW-Authenticate"] = fmt"""Basic realm="{realm}", charset="UTF-8""""
    request.respond(401, headers, failureBody)
    return

# when isMainModule and true:
#   import benchy
#   const runs = 100_000
#   timeit "old":
#     for idx in 0 .. runs:
#       assert ("foo", "baa2") == splitBasicAuth("Basic Zm9vOmJhYTI=")
#       assert ("", "") == splitBasicAuth("Basic ")
#   timeit "new2":
#     for idx in 0 .. runs:
#       assert ("foo", "baa2") == splitBasicAuth2("Basic Zm9vOmJhYTI=")
#       assert ("", "") == splitBasicAuth("Basic ")
#   timeit "new3":
#     for idx in 0 .. runs:
#       assert ("foo", "baa2") == splitBasicAuth3("Basic Zm9vOmJhYTI=")
#       assert ("", "") == splitBasicAuth("Basic ")

when isMainModule and true:
  import tables

  var dummyUserTable: Table[string, string]
  dummyUserTable["david"] = "password"
  dummyUserTable["peter"] = "p4ssw0rd"

  proc dummyTestTable*(user, pass: string): bool =
    {.gcsafe.}:
      if not dummyUserTable.hasKey(user): return false
      return dummyUserTable[user] == pass

  proc dummyTest*(user, pass: string): bool =
    const dummyUser = "foo"
    const dummyPass = "baa2"
    return dummyUser == user and dummyPass == pass

  proc indexHandler(request: Request) =
    var headers: HttpHeaders
    headers["Content-Type"] = "text/plain"
    request.respond(200, headers, "Hello, World!")

  var router: Router
  router.get("/", indexHandler.requiresAuth(dummyTest))
  router.get("/another", indexHandler.requiresAuth(dummyTestTable))

  let server = newServer(router)
  echo "Serving on http://localhost:8080"
  server.serve(Port(8080))
