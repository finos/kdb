qclone
======

Allow a `q` process to \"clone\" itself using `fork(2)` in an orderly
way to permit offloading of long-running queries or disk writes so that
the parent `q` process can continue to process update events.

**Note: Do not use `qclone` if your `*.q` script uses plugins which
create helper threads or uses any kind of q helper thread like `-s` **

(c.f.
<http://www.linuxprogrammingblog.com/threads-and-fork-think-twice-before-using-them>)


qclone Background
-----------------

The single-threaded nature of the underlying `q` interpreter can cause
problems for in-memory databases that are used by multiple clients with
medium-to-long-running queries.

`qclone` attempts to solve this problem for use cases where the time
required to disconnect/reconnect from the q server does not impose a
significant performance penalty on the overall system.

The `qclone` name is inspired by the fact that `clone(...)` is the
function on Linux that does the heavy lifting for `fork(2)`.

When a client connects using, the `q` process calls `fork(2)` and the
client is talking to a clone of the parent.

This should not incur heavy increase of RAM utilization since the
`fork(2)` manpage says:

> Under Linux, fork is implemented using copy-on-write pages, so the
> only penalty incurred by fork is the time and memory required to
> duplicate the parent\'s page tables, and to create a unique task
> structure for the child.

To ensure that the clone does not interfere with the parent\'s socket
connections, the clone closes its server port and handles other than the
one for the client.

Nice side effects of having a clone:

-   data may be mutated without affecting the parent (effectively making
    the parent read-only)
-   client requests which may crash the q interpreter will be contained
    by the clone

Problems with having a clone:

-   Code will have to be put in place to prevent clashing I/O. (Writing
    data files, logs, etc.)

To get a fresh snapshot of the data, the client must disconnect and
reconnect.

qclone Caveats
--------------

Even though the memory is copy-on-write, some systems may want enough
swap space on the box to cover the worst-case-scenario of the child
process somehow writing to all of the shared pages! That means the
process will not start up instead of mysteriously dying later due to
\"Out of Memory: Killed process\".

-   <http://stackoverflow.com/questions/3613649/why-does-cow-mmap-fail-with-enomem-on-sparse-files-larger-than-4gb>

Easiest thing to do is make sure that there\'s sufficient swap space on
the box. Alternatively, you\'ll have to set the following:

-   `/proc/sys/vm/overcommit_memory`
-   `/proc/sys/vm/overcommit_ratio`

qclone Usage
------------

**If clones are to be spawned from within client requests, which is true
for most of the below use cases, the q process needs to be run with
`-u 0`.** This is because the clone initialization procedure requires
access to `/proc` to find the handles opened by the current process so
it can close them, and `/proc` is an absolute path that is blocked by
the default `-u 1` restrictions. If you try to spawn a clone in a
process running with `-u 1` you will see an \'access error on the
console.

Three kinds of client-facing behaviour are supported:

1.  **Clone Per HTTP Request.** When a client makes an HTTP request, a
    clone is created to process the request, render the output, and then
    exit. Note that the table browser is stateful, so the vanishing
    clones confuse it. It may be suitable for longer-running queries or
    I/O bound tasks such as table maintenance.
    -   Use `.finos.qclone.activateZph[]` to enable this capability.

2.  **Clone Per `q` Session.** When a `q` client connects, it will
        get its own client which stays alive until the client
        disconnects. Useful for running a number of operations on a
        snapshot of the data.
    -   Use `.finos.qclone.activateZpo[]` to enable this capability.

3.  **Clone Per `q` Query.** When a `q` client issues a query, it
        will get its own client which stays alive long enough to send
        back the result and then exits.
        
4. **Spawn a task.** Clones the
        current process for a long-running operation that has a useful
        side effect or will connect back to the parent to send a
        result.
        
5. **Offload HTTP.** Clones the current process for a
        long-running operation that is supposed to return data to an
        HTTP client.

The clone does not receive updates, so the client will have to reconnect
if it wants to see the latest data.

Spawning A Task
---------------

    .finos.qclone.spawn[lambdaThatReturnsStatusCode]

The *lambdaThatReturnsStatusCode* argument can actually take two forms:

1.  a q lambda or projection that takes no arguments (or rather one
    argument that is ignored)
    -   useful if kicking off a single task
2.  a general list with lambda as the first argument and its arguments
    as the remaining elements
    -   makes it easier to generate a list of related work items

Use `.finos.qclone.newChildHandler[newChildPid;eventType]` and
`.finos.qclone.oldChildHandler[...]` (described below) to look for return
codes from spawned children to see if they were successful or need
respawning.

For a fully-worked example, see
[\#Spawning\_Example](#Spawning_Example).

Offload HTTP
------------

One can selectively offload long-running HTTP requests from within a
function.

1.  `.finos.qclone.activateZphActive[]` will shim `.z.ph` to set
    `.finos.qclone.zphActive` to `1b` when in the context of an HTTP
    request (`0b` otherwise).
    
2. Your function can check for HTTP and
    then offload using
    `.finos.qclone.offloadHttp[lambdaThatReturnsString;contentType]`.

The `lambdaThatReturnsString` will be called as a no-arg function. To
pass useful information to the lambda, create a projection with an
unbound argument called \"ignored\" (usually as the last one).



qclone Callbacks
----------------

### qclone Child Callbacks

Except for the file descriptor to the client, all file descriptors are
closed when the child process is created.\<br/\> To create a
child-specific context (such as opening a log file), use a
[shim](KDB/Cookbook/DebuggingQ#Shim_a_function_to_capture_print) to add
actions to the null handlers below:

-   `.finos.qclone.childZpoHandler:{[]}` // Called in child when child fork
    is complete.
-   `.finos.qclone.childZpcHandler:{[]}` // Called in child when child will
    exit.
-   `.finos.qclone.childZphHandler:{[]}` // Called in child right before
    evaluating expression.
-   `.finos.qclone.childZpgHandler:{[]}` // Called in child right before
    evaluating expression.
-   `.finos.qclone.childSpawnHandler:{[]}` // Called in child when child
    fork is complete.
-   `.finos.qclone.childOffloadHttpHandler:{[]}` // Called in child when
    child fork is complete.



### qclone Parent Callbacks

Callbacks in the parent process can be used to track child processes.
This can be useful for maintaining a pool of worker processes, some of
which may have died due plugin crahses or exhausting their workspace:

-   `.finos.qclone.newChildHandler:{[newChildPid;eventType]}` // Called in
    parent when child process is created.
-   `.finos.qclone.oldChildHandler:{[oldWaitDictPid;eventType]}` // Called
    in parent when child process is reaped. See `.finos.clib.WAIT_PROTO` .

Checks for zombie children occur each time a clone process is about to
be created. To activate additional timer-based checking, use:

-   `.finos.qclone.activateAutoReap[intervalMillis]`



qclone QandA
------------

-   Q: Is it reasonable to fork a `q` process?
-   A: Up through kdb+ 2.2, the `-s <n>` option forked multiple
    processes, so it\'s something `q` used to do internally.

<!-- -->

-   Q: How is this different from having a pool of `q` processes behind
    a load balancer?
-   A: The main advantages are:
    -   lower memory footprint
    -   no concerns about race conditions and server affinity
    -   ticker plant or master QDB process does not experience increased
        load due to extra subscribers

<!-- -->

-   Q: Does `fork(2)` interact properly with `mmap(2)`?
-   A: According to [Wikipedia](http://en.wikipedia.org/wiki/Mmap),
    \"Memory shared by mmap is kept visible across a fork.\".

<!-- -->

-   Q: How will the `fork(2)` interact with on-disk tables?
-   A: `q` mmaps column files in the context of a query. By the time the
    main thread is free to handle `.z.po`, there would be no active
    queries.

<!-- -->

-   Q: What\'s the intended use case for `qclone`?
-   A: `qclone` was developed as a PoC as a possible solution for
    \"state of the world\" queries for the \"CPS Message Bus\" project.

<!-- -->

-   Q: What are the limitations of using `.z.ph` with `fork(2)` ?
-   A: The HTTP workspace viewer works except for paging through large
    tables since the `.z.ph` implementation is stateful, but that state
    is lost when the child dies after servicing the initial HTTP
    request. Customized `.z.ph` handlers which are stateless should be
    fine.

<!-- -->

-   Q: How does this affect other plugins?
-   A: The child progress aggressively closes file descriptors. This
    will disable any pipes set up to alert the main `q` thread of
    callbacks. This should also close any file descriptors used by
    middleware, preventing data from flowing in. However, plugins which
    create their own threads **may** corrupt the input stream as the
    parent and child processes compete for data. Therefore, use of
    `qclone` is recommended only for `q` programs with %RED%plugins that
    do not use helper threads[]{.twiki-macro .ENDCOLOR}.

<!-- -->

-   Q: What happens to the console when a child is created?
-   A: The child is attached to the same console as the parent, so input
    may go to the parent, child, or split between the two. It can make
    debugging more difficult, so a command line option to control
    whether `qclone` is active or not can be helpful.

<!-- -->

-   Q: Any other capacity issues to keep in mind?
-   A: Clients using the `q` protocol to connect must be well behaved
    and disconnect as soon as possible. Depending on the rate of
    mutation of the data, clients may end up consuming significant
    amounts of RAM. Any setup should be stress tested to check for file
    descriptor leaks, etc.

<!-- -->

-   Q: How do I control the number of child processes?
-   A: The parent could shim `.finos.qclone.newChildHandler[]` so that it
    checks the number of rows returned by
    `.finos.qclone.getChildProcesses[]`. It could call
    `.finos.qclone.reap[]` in a loop and
    only return control when the child count is sufficiently low.

Memory Accounting
-----------------

-   RSS (Resident Set Size) shown in `top(1)` doesn\'t account for the
    sharing between processes.
-   The `smem` utility is a Python script which reports USS (Unique Set
    Size) and PSS (Proportional Set Size).
    -   
Spawning Example
----------------

For example, a clone of an RDB could write checkpoint-related data using
a clone. If the clone returns an exit code of `0` (indicating success),
the parent knows that it can delete the persisted data to reduce the
memory footprint.

Here\'s some example code to spawn child processes and get their exit
codes.


    .finos.qclone.oldChildHandler:{[prevHandler;oldWaitDictPid;eventType]
      d:oldWaitDictPid;
      childPid:d`pid;     // Correlate with information stashed by PID if you want.
      0N!(`reapedChild;childPid);
      show d;
      prevHandler[];
      if[d[`stopped] | d[`continued];
         .finos.log.error"Should not happen!  waitpid(3) *not* passed WUNTRACED/WCONTINUED!";
        ];
      // Decode how the child died.
      $[d`signaled;
        0N!(`diedWithSignal;d`termsig);
        d`coredump;
        0N!`diedWithCore;
        d`exited;
        $[0x00=d[`status];
          0N!`noProblems;
          0N!(`exitedWithStatus;`int$d`status)
         ];
       ];
     }[.finos.qclone.oldChildHandler;;]


    // This is the worker function to be run on the child side.
    // The .z.i will show you the PID under which it is running.
    lambdaThatReturnsStatusCode:{[statusCode;sleepSeconds;notUsed]
      0N!(`lambda;`begin;.z.i);
      system"sleep ",string sleepSeconds;
      statusCode
     }

    // Stash the PIDs of the processes spawned if you want
    //  to correlate things (partition you were writing, etc.)
    //  for some kind of action on the parent side (Netcool, etc.).
    // Otherwise, just pass any necessary information to the lambda.
    childPid0:.finos.qclone.spawn lambdaThatReturnsStatusCode[99;10;]
    0N!(`spawned0;childPid0);
    childPid1:.finos.qclone.spawn lambdaThatReturnsStatusCode[0;10;]
    0N!(`spawned1;childPid1);

Note that `qclone` does not play nicely with other plugins that create
threads/locks. You\'ll have to do a cost/benefit analysis on whether it
makes sense to move those plugins to a \"helper\" q process and make
calls to the helper over IPC.

