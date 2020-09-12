//### fork / waitpid used by qclone.

// requires FFI

// bind doesn't support null arg?
// Just throw it away and pass dummy int.
.finos.clib.fork:{[f;arg]
  f 0i}[.ffi.bind[`fork;enlist"i";"i"];]

/usr/include/sys/wait.h
.finos.clib.WAIT_ANY:-1i
// /usr/include/bits/waitflags.h
.finos.clib.WNOHANG:1i

/usr/include/asm-generic/errno-base.h
.finos.clib.ECHILD:10i      /* No child processes */
.finos.clib.EFAULT:14i      /* Bad address */

.finos.clib.waitpid:.ffi.bind[`waitpid;"iIi";"i"]

.finos.clib.testBitFlag:{[x;y]
  any(0b vs x)&0b vs y}

.finos.clib.bitAnd:{[x;y]
  2 sv(0b vs x)&0b vs y}

.finos.clib.waitNohang:{[]
  // Storage for status.
  status_ints:enlist 0Ni;
  pid:.finos.clib.waitpid(.finos.clib.WAIT_ANY;status_ints;.finos.clib.WNOHANG);

  // Break out the bytes, little-endian.
  status_bytes:reverse 0x00 vs status_ints[0];
  .finos.log.debug"status_bytes=",-3!status_bytes;
  status0:status_bytes[0];

  wexitstatus:status_bytes[1];
  wtermsig:.finos.clib.bitAnd[status0;0x7f];
  wstopsig:wexitstatus;
  wifexited:0=wtermsig;
  wifsignaled:0<(1+wtermsig)div 2
  wifstopped:status0=0x7f;
  wcoreflag:.finos.clib.bitAnd[status0;0x80];

  statusDict:`pid`exited`status`signaled`termsig`coredumped`stopped`stopsig!(
    pid
    ;wifexited
    ;wexitstatus
    ;wifsignaled
    ;wtermsig
    ;wcoreflag
    ;wifstopped
    ;wstopsig);

  statusDict}


//### write / close

// Close file descriptors that weren't created via hopen.
.finos.clib.close0:.ffi.bind[`close;enlist"i";"i"]

.finos.clib.close:{[x]
  .finos.clib.close0`int$x}

// Aggressive shutdown to avoid hanging due to libs that could deadlock.
.finos.clib.underscoreExit0:.ffi.bind[`$"_exit";enlist"i";"i"]

.finos.clib.underscoreExit:{[x]
  .finos.clib.underscoreExit0`int$x}

// enable / disable blocking I/O - NOP for now
.finos.clib.setBlocking:{[handle;onOff]}

.finos.clib.write0:.ffi.bind[`write;"igj";"i"]

.finos.clib.write:{[handle;buf]
  .finos.clib.write0(`int$handle;buf;count buf)}

