import tables
import mummy, mummy/routers
import mummyBasicAuth

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
