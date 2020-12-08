// ### qclone

// NOTE: offloadHttp doesn't work properly until the
//   hclose fix of 2.8.20120420.

.finos.sys.errorTrapAt:@[;;]

// Add help.
.help.DIR[`qclone]:`$"offload clients/tasks to clone process(es)"
.finos.qclone.priv.help: enlist "Support for offloading work to clone processes."

// Select which kind of serialization to use.
// Compressed only works with clients that speak the kdb+2.6 protocol.
.finos.qclone.compressedSerialization:0b

// Known event types.
.finos.qclone.EVENT_TYPES:`zpo`zph`zpg`spawn

// Track what we're activating.
//  Don't want multiple layers of the same shim.
//  zpo and zpg handling are mutually exclusive.
.finos.qclone.priv.activated:`symbol$()

// Called in child when child fork is complete.
// Shim to hook in additional actions.
.finos.qclone.childZpoHandler:{[]}
// Called in child when child will exit.
// Shim to hook in additional actions.
.finos.qclone.childZpcHandler:{[]}
// Called in child right before evaluating expression.
// Shim to hook in additional actions.
.finos.qclone.childZphHandler:{[]}
// Called in child right before evaluating expression.
// Shim to hook in additional actions.
.finos.qclone.childZpgHandler:{[]}
// Called in child right before evaluating lambdaThatReturnsStatusCode.
// Shim to hook in additional actions.
.finos.qclone.childSpawnHandler:{[]}
// Called in child right before evaluating lambdaThatReturnsString.
// Shim to hook in additional actions.
.finos.qclone.childOffloadHttpHandler:{[]}

// Functions in parent for child events.
// Useful for maintaining a pool of children in case some vanish.

// Called in parent when child process is created.
// Shim to hook in additional actions.
// @param newChildPid PID of newly-created child.
// @param eventType One of `zpo`zph`zpg to indicate event which triggered fork(2).
// @return Nothing.
.finos.qclone.newChildHandler:{[newChildPid;eventType]}
// Called in parent when child process is reaped.
// Shim to hook in additional actions.
// @param oldChildWaitDict Dictionary like .finos.clib.wait_PROTO with child termination information.
// @param eventType One of `zpo`zph`zpg`spawn to indicate event which triggered fork(2).
// @return Nothing.
.finos.qclone.oldChildHandler:{[oldChildWaitDict;eventType]}
// Table for tracking child processes created.
.finos.qclone.priv.childProcesses:([pid:`int$()]eventType:`symbol$();startTime:`timestamp$())

// Function to return childProcesses table to reduce likelihood
//  of accidental mutation.
// @return Value of .finos.qclone.priv.childProcesses.
.finos.qclone.getChildProcesses:{[]
  .finos.qclone.priv.childProcesses
 }

// Function which receives the table of possibly-live children.
// The wrapper functions on .z.po, .z.pc., .z.ph, .z.pg aren't
//  going to be removed.  So further connections will mess things up.
// Only useful for cleanup on process exit.
// @param childProcessesTable Last-known state of .finos.qclone.priv.childProcesses .
// @return Nothing.
.finos.qclone.unloadHandler:{[childProcessesTable]}
// Track children created and fire user event handler.
// @param newChildPid PID of child process created by fork(2).
// @return Nothing.
.finos.qclone.priv.newChild:{[newChildPid;eventType]
  `.finos.qclone.priv.childProcesses upsert (newChildPid;eventType;.z.P);
  .[.finos.qclone.newChildHandler
   ;(newChildPid;eventType)
   ;{[x].finos.log.error".finos.qclone.newChildHandler: ",
                     " newChildPid=",string[newChildPid],", eventType=",string[eventType],
                     ", signaled: ",-3!x}
   ];
 }
// Track children reaped and fire user event handler.
// @param oldChildWaitDict Dictionary like .finos.clib.wait_PROTO with child termination information.
// @return Nothing.
.finos.qclone.priv.oldChild:{[oldChildWaitDict]
  oldChildPid:oldChildWaitDict`pid;
  eventType:.finos.qclone.priv.childProcesses[oldChildPid]`eventType;
  .finos.log.debug".finos.qclone.priv.oldChild: oldChildPid=",string[oldChildPid],", eventType=",string eventType;
  delete from`.finos.qclone.priv.childProcesses where pid=oldChildPid;
  .[.finos.qclone.oldChildHandler
   ;(oldChildWaitDict;eventType)
   ;{[oldChildWaitDict;eventType;signal].finos.log.error".finos.qclone.oldChildHandler: ",
                     " oldChildWaitDict=",(-3!oldChildWaitDict),", eventType=",string[eventType],
                     ", signaled: ",-3!signal}[oldChildWaitDict;eventType;]
   ];
 }
// Dummy dictionary in case waitpid(...) fails.
.finos.qclone.priv.DUMMY_WAIT_NOHANG_DICT:enlist[`pid]!enlist -1
// Take the opportunity to clean up zombie children.
// @return Nothing.
.finos.qclone.reap:{[]
  while[((oldChildWaitDict:@[.finos.clib.waitNohang;(::);.finos.qclone.priv.DUMMY_WAIT_NOHANG_DICT])`pid) > 0
       ;.finos.qclone.priv.oldChild oldChildWaitDict];
 }

.finos.qclone.priv.setupChildContextCommon:{
  // hclose all non-client handles so we don't
  //  consume anything destined for the parent.
  .finos.log.debug".finos.qclone.priv.setupChildContext: .z.W=",(-3!.z.W),", .z.w=",(-3!.z.w);
  .finos.qclone.isClone:1b;
  fds:except[;0 1 2i]"I"$string key `$":/proc/",string[.z.i],"/fd";
  @[hclose;;(::)]each except[;.z.w]fds,key .z.W;
  // Clear the list of children, since they're my siblings now.
  delete from `.finos.qclone.priv.childProcesses;
 };

// Close all file descriptors except the one to the client.
// Prevents interference with I/O streams on parent process.
// @return Nothing.
.finos.qclone.priv.setupChildContext:{[]
    system"p 0";                  // Don't interfere with incoming connections.
    .finos.qclone.priv.setupChildContextCommon[];
    };

// Do some accounting and fire off event handlers.
// Close off .z.w to avoid interfering with the child's communication with the client.
// @param newChildPid PID of newly-created child.
// @param eventType One of `zpo`zpg since this function is shared by both kinds of events.
// @return Nothing.
.finos.qclone.priv.forkedParent:{[newChildPid;eventType]
  info:".z.i=",string[.z.i],", .z.w=",string[.z.w],
       ", newChildPid=",string[newChildPid],", eventType=",string[eventType];
  .finos.log.debug".finos.qclone.priv.forkedParent0: ",info;
  .finos.qclone.priv.newChild[newChildPid;eventType];
  // hclose .z.w only for .z.po and .z.pg handling.
  // Returning anything (even generic null (::)) results in serializable
  //  data which could corrupt the stream between the child and the client.
  // Closing .z.w on .z.ph confuses the parent for the next HTTP connection.
  // (Probably a q bug.)
  // Spawn doesnt make use of .z.w.
  // offloadHttp doesn't hclose properly until 2.8.20120420.
  if[eventType in`zpo`zpg`offloadHttp
    ; @[hclose;.z.w;(::)]
    ];
  .finos.log.debug".finos.qclone.priv.forkedParent1: ",info;
 }
// Handler for .z.pc to make child to exit when client disconnects.
// @return Never.
.finos.qclone.priv.forkedChildZpc:{[]
  .finos.log.debug".finos.qclone.priv.forkedChildZpc: .z.i=",string .z.i;
  @[.finos.qclone.childZpcHandler;(::);{[x].finos.log.error".finos.qclone.childZpcHandler signaled: ",-3!x}];
  exit 0;
 }
// After fork, child is handed off to this function to manage
//  file descriptors, do some accounting, and fire off user handlers.
// @returns Nothing.
.finos.qclone.priv.forkedChildZpo:{[]
  info:".z.i=",string[.z.i],", .z.w=",string[.z.w];
  .finos.log.debug".finos.qclone.priv.forkedChildZpo0: ",info;
  .finos.qclone.priv.setupChildContext[];
  // Install a handler to exit on close.
  $[-11h=type key`.z.pc         // Handler exists?
   // Shim.  Do forkedChildZpc last because it exits.
   ;.z.pc:{[oldZpc;w]@[oldZpc;w;(::)];.finos.qclone.priv.forkedChildZpc .z.w}[.z.pc;]
   // Assign.
   ;.z.pc:.finos.qclone.priv.forkedChildZpc
   ];
  // Call handler after handles are all set up.
  @[.finos.qclone.childZpoHandler;(::);{[x].finos.log.error".finos.qclone.childZpoHandler signaled: ",-3!x}];
  .finos.log.debug".finos.qclone.priv.forkedChildZpo1: ",info;
 }
// Handler to call from .z.po to associate client session with a clone.
// @param ignoredW Handler on .z.po receives handle for client.  But we don't use it.
// @return Nothing.
.finos.qclone.priv.forkConnectionZpo:{[ignoredW]
  rc:.finos.clib.fork[];
  $[rc>0
   ;.finos.qclone.priv.forkedParent[rc;`zpo]
   ;.finos.qclone.priv.forkedChildZpo[]
   ];
  // .z.po doesn't return anything.
 }

.finos.qclone.priv.help,:(
  ".finos.qclone.activateZpo[]";
  "    Hooks up .z.po handler for clone-per-session capability.")
// Hook up .z.po handler for clone-per-session capability.
// @return Nothing.
.finos.qclone.activateZpo:{[]
  if[`zpo in .finos.qclone.priv.activated
    ; : (::)   // Already activated.
    ];
  if[`zpg in .finos.qclone.priv.activated
    ; '"activateZpg already active and mutually exclusive"
    ];
  $[-11h=type key `.z.po        // Handler exists?
   ;.z.po:{[oldZpo;w]@[oldZpo;w;(::)];.finos.qclone.priv.forkConnectionZpo w}[.z.po;]
   // Assign.
   ;.z.po:.finos.qclone.priv.forkConnectionZpo
   ];
  .finos.qclone.priv.activated,:`zpo;
 }
// After fork, child is handed off to this function to manage
//  file descriptors, do some accounting, and fire off user handlers.
// @param oldZph Shimmed http renderer.  Want to execute in the child.
// @param x Whatever the original .z.ph handler rendered into text.
// @return Never.
.finos.qclone.priv.forkedChildZph:{[oldZph;x]
  info:".z.i=",string[.z.i],", .z.w=",string[.z.w],", x=",(-3!x);
  .finos.log.debug".finos.qclone.priv.forkedChildZph0: ",info;
  .finos.qclone.priv.setupChildContext[];
  // Call handler after handles are all set up.
  @[.finos.qclone.childZphHandler;(::);{[x].finos.log.error".finos.qclone.childZphHandler signaled: ",-3!x}];
  // Process the input.
  r:@[oldZph;x;{[x]$[10h=type x;x;-3!x]}];
  // Can't return the string since it makes it more complicated
  //  to figure out when to exit.
  // Force feed the string down the handle.
  .finos.qclone.priv.blockingWriteAndClose r;
  .finos.log.debug".finos.qclone.priv.forkedChildZph1: ",info;
  exit 0;
 }
// Handler to call from .z.ph to have query processed by a clone.
// @param x Whatever the original .z.ph handler rendered into text.
// @return Empty string to avoid interfering with the child's communication with the client.
.finos.qclone.priv.forkConnectionZph:{[oldZph;x]
  rc:.finos.clib.fork[];
  $[rc>0
   ;.finos.qclone.priv.forkedParent[rc;`zph]
   ;.finos.qclone.priv.forkedChildZph[oldZph;x]  // Will exit.
   ]
  ""
 }

.finos.qclone.priv.help,:(
  ".finos.qclone.activateZph[]";
  "    Hooks up .z.ph handler for clone-per-request capability.")
// Hook up .z.ph handler for clone-per-query capability.
// @return Nothing.
.finos.qclone.activateZph:{[]
  if[`zph in .finos.qclone.priv.activated
    ; : (::)   // Already activated.
    ];
  .z.ph::.finos.qclone.priv.forkConnectionZph[.z.ph;];
  .finos.qclone.priv.activated,:`zph;
 }
// Take q query result and set the message type to
//  indicate that this is response to a sync request.
// @param x Value to return to the client.
// @return Byte vector with serialized representation.
.finos.qclone.priv.serialize:{[x]
  r:$[.finos.qclone.compressedSerialization;-18;-8]!x;
  // Poke in the byte that says this is a result message.
  //  http://code.kx.com/wiki/Reference/ipcprotocol#serializing_an_integer_of_value_1
  r[1]:0x02;
  r
 }

.finos.qclone.priv.blockingWriteAndClose:{[x]
  total:count x;
  sent:0;
  rc:0;
  .finos.clib.setBlocking[.z.w;1b];
  while[sent<total
       ;rc:.finos.clib.write[.z.w;sent _ x]
       ;sent+:rc
       ];
  hclose .z.w}

// After fork, child is handed off to this function to manage
//  file descriptors, do some accounting, and fire off user handlers.
// @param oldZpg Shimmed http renderer.  Want to execute in the child.
// @param x Whatever the original .z.ph handler rendered into text.
// @return Never.
.finos.qclone.priv.forkedChildZpg:{[oldZpg;x]
  info:".z.i=",string[.z.i],", .z.w=",string[.z.w],", x=",(-3!x);
  .finos.log.debug".finos.qclone.priv.forkedChildZpg0: ",info;
  .finos.qclone.priv.setupChildContext[];
  // Call handler after handles are all set up.
  @[.finos.qclone.childZpgHandler;(::);{[x].finos.log.error".finos.qclone.childZpgHandler signaled: ",-3!x}];
  // Process the input.
  r:@[oldZpg;x;{[x]$[10h=type x;x;-3!x]}];
  // Can't return the string since it makes it more complicated
  //  to figure out when to exit.
  // Force feed the string down the handle.
  .finos.qclone.priv.blockingWriteAndClose .finos.qclone.priv.serialize r;
  .finos.log.debug".finos.qclone.priv.forkedChildZpg1: ",info;
  exit 0;
 }
// Handler to call from .z.pg to have query processed by a clone.
// @param x Whatever the original .z.pg handler rendered into text.
// @return Generic null, to be discarded since the client handle was closed.
.finos.qclone.priv.forkConnectionZpg:{[oldZpg;x]
  rc:.finos.clib.fork[];
  $[rc>0
   ;.finos.qclone.priv.forkedParent[rc;`zpg]
   ;.finos.qclone.priv.forkedChildZpg[oldZpg;x]  // Will exit.
   ];
  (::)
 }

.finos.qclone.priv.help,:(
  ".finos.qclone.activateZpg[]";
  "    Hooks up .z.pg handler for clone-per-query capability.")
// Hook up .z.pg handler for clone-per-query capability.
// @return Nothing.
.finos.qclone.activateZpg:{[]
  if[`zpg in .finos.qclone.priv.activated
    ; : (::)   // Already activated.
    ];
  if[`zpo in .finos.qclone.priv.activated
    ; '"activateZpo already active and mutually exclusive"
    ];
  $[-11h=type key `.z.pg        // Handler exists?
   ;.z.pg:{[oldZpg;w]@[oldZpg;w;(::)];.finos.qclone.priv.forkConnectionZpg w}[.z.pg;]
   // Assign.
   ;.z.pg:.finos.qclone.priv.forkConnectionZpg[value;]
   ];
  .finos.qclone.priv.activated,:`zpg;
 }
// After fork, child is handed off to this function to manage
//  file descriptors, do some accounting, and fire off user handlers.
// @param lambdaThatReturnsStatusCode Function passed by user.  Takes no arguments.
.finos.qclone.priv.forkedChildSpawn:{[lambdaThatReturnsStatusCode;args]
    info:".z.i=",string[.z.i],", .z.w=",string[.z.w];
    .finos.log.debug".finos.qclone.priv.forkedChildSpawn0: ",info;
    .finos.qclone.priv.setupChildContext[];
    // Call handler after handles are all set up.
    @[.finos.qclone.childSpawnHandler;(::);{[x].finos.log.error".finos.qclone.childSpawnHandler signaled: ",-3!x}];
    // Run the lambda.
    r:.[lambdaThatReturnsStatusCode;(),args;{[x]$[10h=type x;x;-3!x]}];
    // Can't return the string since it makes it more complicated
    .finos.log.debug".finos.qclone.priv.forkedChildSpawn1: ",info,", result: ",-3!r;
    // If result isn't an integer, use -1 as status code.
    .finos.clib.underscoreExit $[type[r]in -6 -7h;r;-1];
    };

.finos.qclone.priv.forkFailedHandler:{[err]
  'err}

.finos.qclone.priv.help,:(
  ".finos.qclone.spawn[lambdaThatReturnsStatusCode]";
  "     Create a clone and run the lambda.";
  "     lambdaThatReturnsStatusCode can be a lambda like {1+2}";
  "     or a lambda with arguments like ({x+y};1;2) or ({x+5};1}")
// Spawn a child process and run the lambda.
// @param lambda or (lambda;args1;..;argN) lambda(with optional arguments) to do work and then exit with a status code.
// @return newChildPid to the parent.
.finos.qclone.spawn:{[f]
  // To make sure code execution doesm't break out on a 
  //"fork. OS reports: Resource temporarily unavailable" error due to hitting
  // your ulimit for processes open
  rc:@[.finos.clib.fork;(::);.finos.qclone.priv.forkFailedHandler];
  // Only run the forkedParent[...] handler if fork(2) was successful.
  $[rc>0;
    .finos.qclone.priv.forkedParent[rc;`spawn];
    .finos.qclone.priv.forkedChildSpawn[first f;$[1<count f;1_f;(::)]]];  // Will exit.
  rc}

// After fork, child is handed off to this function to manage
//  file descriptors, do some accounting, and fire off user handlers.
// @param lambdaThatReturnsString Function passed by user.
//    The lambda takes no arguments.
//    Returns a string to be sent to the HTTP client.
.finos.qclone.priv.forkedChildOffloadHttp:{[lambdaThatReturnsString;contentType]
  info:".z.i=",string[.z.i],", .z.w=",string[.z.w];
  .finos.log.debug".finos.qclone.priv.forkedChildOffloadHttp0: ",info;
  .finos.qclone.priv.setupChildContext[];
  // Call handler after handles are all set up.
  @[.finos.qclone.childOffloadHttpHandler;(::);{[x].finos.log.error".finos.qclone.childOffloadHttpHandler signaled: ",-3!x}];
  // Run the lambda.
  r:@[lambdaThatReturnsString;(::);{[x]$[10h=type x;x;-3!x]}];
  // If they didn't return a string, do a simple render.
  if[10h<>type r;
    ;r:.h.pre .Q.s2 r
    ];
  // Can't return the string since it makes it more complicated
  //  to figure out when to exit.
  // Force feed the string down the handle.
  .finos.qclone.priv.blockingWriteAndClose .h.hy[contentType;]r;
  // Can't return the string since it makes it more complicated
  .finos.log.debug".finos.qclone.priv.forkedChildOffloadHttp1: ",info;
  exit 0;
 }

.finos.qclone.priv.help,:(
  ".finos.qclone.offloadHttp[lambdaThatReturnsString;contentType]";
  "     Create a clone and run the lambda.  Send string returned from lambda to HTTP client.")
// OffloadHtml a child process and run the lambda.
// @param lambdaThatReturnsString Lambda to do work and then give a string as the result.
// @return Empty string to avoid interfering with the child's communication with the client.
.finos.qclone.offloadHttp:{[lambdaThatReturnsString;contentType]
  rc:.finos.clib.fork[];
  $[rc>0
   ;.finos.qclone.priv.forkedParent[rc;`offloadHttp]
    // Function call below will cause clone process to exit when it's done.
   ;.finos.qclone.priv.forkedChildOffloadHttp[lambdaThatReturnsString;contentType]
   ];
 }

// This gets set to 1b so functions called from HTML
//  interface can exhibit special behaviour for
//  StratStudio.
.finos.qclone.zphActive:0b
.finos.qclone.oldZph:.z.ph

// Shim to set the variable.
.finos.qclone.priv.zphActiveHandler:{[arg]
  .finos.qclone.zphActive:1b;
  // Don't need protected eval since HTML rendering coe
  //  does that already.
  r:.finos.qclone.oldZph arg;
  .finos.qclone.zphActive:0b;
  r
 }

.finos.qclone.priv.help,:(
  ".finos.qclone.activateZphActive[]";
  "    Hooks up .z.ph handler with shim to maintain .finos.qclone.zphActive flag.")

.finos.qclone.activateZphActive:{[]
  if[`zphActive in .finos.qclone.priv.activated
    ; : (::)   // Already activated.
    ];
  if[not -11h=type key `.z.ph // HTML renderer installed?
    ;'"no HTML handler installed on .z.ph"
    ];
  // Assign.
  .z.ph:.finos.qclone.priv.zphActiveHandler;
  .finos.qclone.priv.activated,:`zphActive;
 }

.finos.qclone.priv.help,:(
  ".finos.qclone.unload[]";
  "    Remove artifacts from .finos.qclone namespace.  (But can't unshim, so only useful on exit.)")
// Try to clean everything up.
// However, the wrapper functions on .z.po, .z.pc., .z.ph, .z.pg aren't
//  going to be removed.  So further connections will mess things up.
// Only useful for cleanup on process exit.
.finos.qclone.unload:{
  @[`.help;`DIR`TXT;_;`qclone]; // Remove help entry.
  .finos.qclone.reap[];       // Clean up remaining zombies.
  r:.finos.qclone.priv.childProcesses;  // Copy the things we need before they're deleted
  func:unloadHandler;                //  so we can perform the callback.
  delete qclone from `.finos;      // Delete entire context and its contents from .finos namespace.
  func r;
 }

.finos.qclone.isClone:0b;  //used by .finos.qclone.spawnPersistent to prevent runaway spawning
.finos.qclone.parentPort:system"p";

//The file handle operations must occur in this specific order.
//Skipping actions or changing their order can cause weird behavior like
//the parent and child fighting over the console, or the parent hanging on exiting.
.finos.qclone.priv.setupPersistentChildContext:{[fun]
    .finos.log.priv.h:-2;  //avoid writing to log files until the clone sets up its own logging
    p:system "p";
    if[p>0;.finos.qclone.parentPort:p];
    .finos.qclone.priv.setupChildContextCommon[];
    system"p 0W";
    .finos.qclone.close 0;
    hopen`:/dev/null;
    system"p 0";
    fun[]};

// Spawns a persistent clone. This is basically an enhanced version of .finos.clib.fork[] that
// fixes some anomalies and allows a real functioning clone to be spawned as a result.
// Since this function calls fork, all the code that follows the call will be executed in the
// clone as well, so this should be the last call inside the function that calls it, or
// check the value of .finos.qclone.isClone to decide which actions to execute.
// Warning: In q version 3.4, the unix domain socket will be deleted after calling this function.
// @param fun A function to execute in the clone (e.g. this could connect back to the parent).
// @return PID (0 in the clone)
.finos.qclone.spawnPersistent:{[fun]
    if[0<.z.w; '"spawnIdleClone must be run from main thread"];
    if[.finos.qclone.isClone; :0i];   //required since this function may be called in each
    pid:.finos.clib.fork[];
    if[0=pid;   //we are the clone
        .finos.sys.errorTrapAt[.finos.qclone.priv.setupPersistentChildContext;fun;{-1 x;exit 1}];
    ];
    pid};

.help.TXT[`qclone]:.finos.qclone.priv.help

// .finos.qclone.activateZph[]
// .finos.qclone.activateZpo[]   // Mutually exclusive with activateZpg.
// .finos.qclone.activateZpg[]   // Mutually exclusive with activateZpo.