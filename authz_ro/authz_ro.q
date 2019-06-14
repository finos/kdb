// Default authorization (authz) handlers for q (.z.ps / .z.pg).
// Only useful if used in conjunction with authentication (authn) handlers!
// i.e. : .z.pw / .z.ac

// The use of setters / getters for global variables facilitates namespace aliasing.


// List of users who will get their parse trees evaluated with
//  the full power of "eval".
// Takes precedence over roUsers.
.finos.authz_ro.priv.rwUsers:enlist .z.u

.finos.authz_ro.addRwUsers:{[userSymOrList]
  /// Add user(s) to list of "rw" users.
  // @param u Symbol or list of symbols for users whose "rw" eval
  //  capability is to be granted.
  .finos.authz_ro.priv.rwUsers::distinct .finos.authz_ro.priv.rwUsers,userSymOrList;
 }

.finos.authz_ro.removeRwUsers:{[userSymOrList]
  /// Remove user(s) from list of "rw" users.
  // @param u Symbol or list of symbols for users whose "rw" eval
  //  capability is to be revoked.
  .finos.authz_ro.priv.rwUsers::.finos.authz_ro.priv.rwUsers except userSymOrList;
 }


.finos.authz_ro.getRwUsers:{[]
  /// Return current list of users with "rw" eval permission.
  .finos.authz_ro.priv.rwUsers}


.finos.authz_ro.isRwUser:{[userSym]
  /// Return 1b if userSym represents a user with read-write access.
  userSym in .finos.authz_ro.priv.rwUsers}


/// List of users who will get their parse trees
//  evaluated with read-only restrictions under "reval".
// Takes precedence over functionWhitelist which makes it easier
//  to grant temporary superuser access.
.finos.authz_ro.priv.roUsers:`symbol$()


.finos.authz_ro.addRoUsers:{[userSymOrList]
  /// Add user(s) to list of "ro" users.
  // @param u Symbol or list of symbols for users whose "ro" eval
  //  capability is to be granted.
  .finos.authz_ro.priv.roUsers::distinct .finos.authz_ro.priv.roUsers,userSymOrList;
 }

.finos.authz_ro.removeRoUsers:{[userSymOrList]
  /// Remove user(s) from list of "ro" users.
  // @param u Symbol or list of symbols for users whose "ro" eval
  //  capability is to be granted.
  .finos.authz_ro.priv.roUsers::.finos.authz_ro.priv.roUsers except userSymOrList;
 }

.finos.authz_ro.getRoUsers:{[]
  /// Return current list of users with "ro" eval permission.
  .finos.authz_ro.priv.roUsers}


.finos.authz_ro.isRoUser:{[userSym]
  /// Return 1b if userSym represents a user with read-only access.
  userSym in .finos.authz_ro.priv.roUsers}


/// List of functions that are allowed to be run by any user.
// Make sure the list doesn't collapse into a symbol list by
//  putting in a non-sym placeholder such as (::) if necessary.
// Whitelist functions should check against an appropriate
//  entitlements model.
.finos.authz_ro.priv.whitelistedFunctions:(tables;`.Q.w;`.q.tables)

.finos.authz_ro.addWhitelistedFunctions:{[lambdaOrSymbolList]
  /// Add function(s) to whitelist.
  .finos.authz_ro.priv.whitelistedFunctions::distinct .finos.authz_ro.priv.whitelistedFunctions,lambdaOrSymbolList;
 }

.finos.authz_ro.removeWhitelistedFunctions:{[lambdaOrSymbolList]
  /// Remove function(s) from whitelist.
  .finos.authz_ro.priv.whitelistedFunctions::.finos.authz_ro.priv.whitelistedFunctions except lambdaOrSymbolList;
 }

.finos.authz_ro.getWhitelistedFunctions:{[]
  /// Return current whitelist.
  .finos.authz_ro.priv.whitelistedFunctions}


.finos.authz_ro.isWhitelistedFunction:{[funcOrName]
  /// Return 1b if funcOrName represents a function that can be
  //  run by a user who is authorized for neither RW nor RO.
  funcOrName in .finos.authz_ro.priv.whitelistedFunctions}


.finos.authz_ro.valueFunc:{[x]
  /// Replacement for "value" with restrictions based on the user's authorization status.

  // Get the parse tree form.
  // p:parse x;
  p:$[10h=type x;
      parse x;
      (value;enlist x)];
  // ReadWrite users get expressions processed using "eval".
  if[.finos.authz_ro.isRwUser .z.u; :eval p];
  // ReadOnly users get expressions processed using "reval".
  if[.z.K >= 3.3;[if[.finos.authz_ro.isRoUser .z.u; :reval p]]];

  // For empty expression, just return null.
  if[(0=count p)|p~(::) ; :(::)];
  // Count not zero. Take the first item as the function.
  f:$[10h=type x; first p; first x];
  // Bail out if function isn't in the whitelist.
  if[not .finos.authz_ro.isWhitelistedFunction f;
      '"Not a whitelisted function: ",-3!f];

  // Evaluate the parse tree symmetrically to reval case.
  eval p};

.finos.authz_ro.priv.orig_zph:.z.ph

.finos.authz_ro.restrictZpg:{[]
  /// Make it easy to activate more restrictive .z.pg / .z.ps .
  
  // Use names instead of values to allow overwriting
  //  of .ms.dotz.valueFunc with even more restrictive
  //  implementation (using E3, for example).
  .z.ps:{`.finos.authz_ro.valueFunc x};
  .z.pg:{`.finos.authz_ro.valueFunc x};
  system"x .z.ph";
 }

.finos.authz_ro.restrictZpg[]

