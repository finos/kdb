# authz_ro - Default Authorization Handlers

## Introduction

Out of the box, kdb+ prioritizes performance and productivity over all else.  As a result, opening a port on the q process allows any client to perform any operation - including arbitrary UNIX commands.  This sort of access is generally not permitted in enterprise environments since IT security takes priority over performance and productivity.

The scope of **authz_ro** is purely that of Authorization (authz).  It is assumed that enterprise kdb users use an Authentication (authn) scheme that interoperates with other platforms (C++, Java, C#, etc.) in their ecosystem

For more information about nonfunctional requiements in Enterprise Environments, see:
* https://finosfoundation.atlassian.net/wiki/spaces/DT/pages/1090158617/Enterprise+kdb+vs.+Small+Team+kdb+


## Authorization Model

**authz_ro.q** installs handlers that take the authenticiated user ID in **.z.u** and check which tier of access they have:
1. **rw** - Read / Write - input evaluated with **value**
2. **ro** - Read Only - input evaluated with **reval**
3. **other** - user may only call functions on the "whitelistedFunction" list.


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

__.finos.authz_ro.addWhitelistedFunctions[__ *lambdaOrSymbolList* __]__
* Add function(s) to whitelist.

__.finos.authz_ro.removeWhitelistedFunctions[__ *lambdaOrSymbolList* __]__
* Remove function(s) from whitelist.

__.finos.authz_ro.getWhitelistedFunctions[ ]__
* Return current whitelist.

__.finos.authz_ro.isWhitelistedFunction[__ *funcOrName* __]__
* Return 1b if funcOrName represents a function that can be run by a user who is authorized for neither RW nor RO.

__.finos.authz_ro.valueFunc[__ *x* __]__
* Replacement for "value" with restrictions based on the user's authorization status.

__.finos.authz_ro.restrictZpg[ ]__
* Make it easy to activate more restrictive .z.pg / .z.ps .

