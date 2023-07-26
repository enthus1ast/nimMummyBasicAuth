import mummy, mummy/routers
import webby/httpheaders, strutils, base64, strformat, parseutils

type
  TestBasicAuth* = proc(user, pass: string): bool {.gcsafe.}

proc splitBasicAuth(val: string): tuple[user, pass: string] =
  try:
    const basic = "Basic "
    if val.len <= basic.len: return
    if not val.startsWith(basic): return
    let deco = val[basic.len .. ^1].decode()
    let pos = parseUntil(deco, result.user, ':', 0) + 1
    result.pass = deco[pos .. ^1]
  except:
    return

proc requiresAuth*(handler: RequestHandler, testProc: TestBasicAuth,
    realm = "Login", failureBody = "please log in",
    headers: HttpHeaders = emptyHttpHeaders()): RequestHandler =
  return proc (request: Request) =
    if "Authorization" in request.headers:
      let (user, pass) = splitBasicAuth(request.headers["Authorization"])
      if testProc(user, pass):
        handler(request)
        return
    var headers: HttpHeaders = headers
    headers["WWW-Authenticate"] = fmt"""Basic realm="{realm}", charset="UTF-8""""
    request.respond(401, headers, failureBody)
    return
