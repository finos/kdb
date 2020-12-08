# authz_ro - Default Authorization Handlers

## Introduction

Out of the box, kdb+ prioritizes performance and productivity over all
else.  As a result, opening a port on the q process allows any client
to perform any operation - including arbitrary UNIX commands.  This
sort of access is generally not permitted in enterprise environments
since IT security takes priority over performance and productivity.

The scope of **authz_ro** is purely that of Authorization (authz).  It
is assumed that enterprise kdb users use an Authentication (authn)
scheme that interoperates with other platforms (C++, Java, C#, etc.)
in their ecosystem

For more information about nonfunctional requiements in Enterprise
Environments, see:
* https://finosfoundation.atlassian.net/wiki/spaces/DT/pages/1090158617/Enterprise+kdb+vs.+Small+Team+kdb+


## Authorization Model

**authz_ro.q** installs handlers that take the authenticiated user ID in **.z.u** and check which tier of access they have:
1. **rw** - Read / Write - input evaluated with **value**
2. **ro** - Read Only - input evaluated with **reval**
3. **other** - user may only call functions registered with a paramFilter.

The paramFilter is a function that takes the arguments from the parse tree
and can:
 a) Rewrite parts of the tree to call safer alternatives to native q primitives.
 b) Signal an error for constructs that are not permitted.


## Background
kdb+ provides numerous hooks for accepting input from a socket:

* Authentication:
 * https://code.kx.com/v2/ref/dotz/#zpw-validate-user
 * https://code.kx.com/v2/ref/dotz/#zac-http-auth-from-cookie

* Authorization:
  * https://code.kx.com/v2/ref/dotz/#zpg-get
  * https://code.kx.com/v2/ref/dotz/#zps-set
  * https://code.kx.com/v2/ref/dotz/#zpi-input
  
Currently, the HTTP GET handler accepts arbitrary commands without
providing hooks to control the level of access.  Safest to expunge
.z.ph until such time as a safe implementation is available.


* HTTP requests:
  * https://code.kx.com/v2/ref/dotz/#zph-http-get
  * https://code.kx.com/v2/ref/dotz/#zpp-http-post

The when **.z.ps** / **.z.pg** / **.z.pi** are not set, the default behavior is to accept any input for evaluation by the interpreter.

## API

__.finos.authz_ro.addRwUsers[__ *userSymOrList* __]__
* Add user(s) to list of "rw" users.

__.finos.authz_ro.removeRwUsers[__ *userSymOrList* __]__
* Remove user(s) from list of "rw" users.

__.finos.authz_ro.getRwUsers[ ]__
* Return current list of users with "rw" eval permission.

__.finos.authz_ro.isRwUser[__ *userSym* __]__
* Return 1b if userSym represents a user with read-write access.

__.finos.authz_ro.addRoUsers[__ *userSymOrList* __]__
* Add user(s) to list of RO users.

__.finos.authz_ro.removeRoUsers[__ *userSymOrList* __]__
* Remove user(s) from list of RO users.

__.finos.authz_ro.getRoUsers[ ]__
* Return current list of users with "rw" eval permission.

__.finos.authz_ro.isRoUser[__ *userSym* __]__
* Return 1b if userSym represents a user with read only access.

__.finos.authz_ro.params.filterVerbsLambdas[__ *x* __]__
* Given a parameter list from parse[...], build an identical tree, but error out if anything executable is detected.

__.finos.authz_ro.addFuncs[__ *lambdaOrSymbolList* __]__
* Add function(s) to whitelist.

__.finos.authz_ro.removeFuncs[__ *lambdaOrSymbolList* __]__
* Remove function(s) from whitelist.

__.finos.authz_ro.getFuncs[ ]__
* Return current whitelist.

__.finos.authz_ro.getParamFilter[__ *funcOrName* __]__
* Get function for filtering parameters of passed function.
 * An empty general list () or general null (::) will be returned if funcOrName was not found.

__.finos.authz_ro.valueFunc[__ *x* __]__
* Replacement for "value" with restrictions based on the user's authorization status.

__.finos.authz_ro.restrictZpg[ ]__
* Make it easy to activate more restrictive .z.pg / .z.ps / .z.pq .


## Configuring authz_ro .

An application based on kdb+ typically consists of multiple
cooperating q processes.  The API here doesn't prescribe how to manage
these entitlements in a distributed manner.  The priority is to lock
down q processes by default to avoid problems with naive users leaving
gaping security holes.

However, future possibilities might include:
  1. Reading entitlements from flat files.
  2. Polling a central entitlements management process.
  3. Registering for async updates from an entitelements management process.

