A simple basic auth handler for the mummy webserver

```
import mummy, mummy/routers
import tables


# A Tester that uses a table as user/password store
var dummyUserTable: Table[string, string]
dummyUserTable["david"] = "password"
dummyUserTable["peter"] = "p4ssw0rd"

proc dummyTestTable*(user, pass: string): bool =
  {.gcsafe.}:
    if not dummyUserTable.hasKey(user): return false
    return dummyUserTable[user] == pass


# A tester that has hard coded username/password
proc dummyTest*(user, pass: string): bool =
  const dummyUser = "foo"
  const dummyPass = "baa2"
  return dummyUser == user and dummyPass == pass


# The ressource that we wanna secure via basic auth
proc indexHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Hello, World!")

var router: Router
router.get("/", indexHandler.requiresAuth(dummyTest)) # this uses the hardcoded username/password
router.get("/another", indexHandler.requiresAuth(dummyTestTable)) # this uses the table

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
```
