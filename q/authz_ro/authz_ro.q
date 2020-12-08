///
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


.finos.authz_ro.params.filterVerbsLambdas:{[x]
  /// Given a parameter list from parse[...],
  //   build an identical tree, but error out
  //   if anything executable is detected.

  // Special case for general null.
  if[x~(::); : x];

  t:type x;
  
  // Recurse on general lists.
  if[0h=t; : .z.s each x];
  // Return anything that's a "pure data" type.
  if[99h>=abs t; : x];
  // Signal an error.
  '"verbs/lambdas disallowed";
 }


/// List of functions that are allowed to be run by any user.
// Make sure the list doesn't collapse into a symbol list by
//  putting in a non-sym placeholder such as (::) if necessary.
// Whitelist functions should check against an appropriate
//  entitlements model.
.finos.authz_ro.priv.funcs:([func:enlist(::)];paramFilter:enlist(::))

.finos.authz_ro.addFuncs:{[lambdaOrSymbolList]
  /// Add function(s) to whitelist.
  `.finos.authz_ro.priv.funcs insert (lambdaOrSymbolList;count[lambdaOrSymbolList]#.finos.authz_ro.params.filterVerbsLambdas)
 }

.finos.authz_ro.addFuncs[(`.q.tables;`.Q.w;.q.tables)]

.finos.authz_ro.removeFuncs:{[lambdaOrSymbolList]
  /// Remove function(s) from whitelist.
  delete from `.finos.authz_ro.priv.funcs where func~/:lambdaOrSymbolList;
 }

.finos.authz_ro.getFuncs:{[]
  /// Return current whitelist.
  .finos.authz_ro.priv.funcs}


.finos.authz_ro.getParamFilter:{[funcOrName]
  /// Get function for filtering parameters of passed function.
  //   An empty general list () or general null (::) will be returned
  //   if funcOrName was not found.
  exec first paramFilter from .finos.authz_ro.priv.funcs where func~\:funcOrName}


.finos.authz_ro.valueFunc:{[x]
  /// Replacement for "value" with restrictions based on the user's authorization status.

  // Get the parse tree form.
  // p:parse x;
  p:$[10h=type x;parse x;x];
  // For empty expression, just return null.
  if[(0=count p)|p~(::) ; :(::)];
  // ReadWrite users get expressions processed using "eval".
  if[.finos.authz_ro.isRwUser .z.u; :eval p];
  // ReadOnly users get expressions processed using "reval".
  if[.z.K >= 3.3;if[.finos.authz_ro.isRoUser .z.u; :reval p]];
  // Count not zero. Take the first item as the function.
  f:first p;

  // Get paramFilter for the desired function.
  paramFilter:.finos.authz_ro.getParamFilter f;
  // Bail out if function isn't in the whitelist.
  if[any paramFilter~/:( ();(::) ) ;
      '"Not a whitelisted function: ",-3!f];

  // Filter the parameters and build a new parse tree.
  p2:enlist[f], paramFilter 1_ p;

  // Go ahead and eval.
  eval p2}

.finos.authz_ro.priv.orig_zph:.z.ph

.finos.authz_ro.restrictZpg:{[]
  /// Make it easy to activate more restrictive .z.pg / .z.ps .
  
  // Use names instead of values to allow overwriting
  //  of .ms.dotz.valueFunc with even more restrictive
  //  implementation (using E3, for example).
  .z.ps:.z.pg:.z.pq:{`.finos.authz_ro.valueFunc x};
  system"x .z.ph";
 }

.finos.authz_ro.restrictZpg[]

