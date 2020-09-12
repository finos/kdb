.finos.log.debug:{-2@x}
.finos.log.error:{-2@x}

\l finos_clib.q
\l finos_qclone.q

t:([]til 3)

// Function to show PID and content.
show_t:{0N!.z.i+t;7i}

.finos.qclone.spawn(show_t)
.finos.qclone.spawn(show_t)

.finos.qclone.reap[]


.finos.qclone.activateZph[]
