\l authz_ro.q

// Test authz by calling .z.pg rather than going
//  through the trouble to create a separate process
//  and calling .z.pg on that...

.finos.authz_ro.removeRwUsers .z.u

t:([]c1:`a`b`c;c2:1 2 3)

// These should run.
.z.pg"tables[]"
.z.pg"tables`."
.z.pg".Q.w[]"

// This should fail since it has a lambda in it.
.z.pg"tables{0N!`hello;`}[]"
