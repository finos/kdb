\l structlog.q

tlog:.finos.structlog.getLogger[]

0N!"rendering log messages as text for flat files";
tlog.debug["thing1";()!()]
tlog.debug["thing2";`a`b!1 2]

0N!"see what's in .finos.structlog.structlogTable";
show .finos.structlog.structlogTable

// Look for log entry where b~2.
// Use "~" instead of "=" since not all dictionaries
//  will return a long for key `b.
0N!"example of querying structlogTable for b=2";
show select from .finos.structlog.structlogTable where {x[`b]~2}each d