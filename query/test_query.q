// symbol column
.test.t0syms:`aa`bb`cc`bb`aa`aa
// string column
.test.t1strs:string .test.t0syms

// table with symbol column
.test.t0syms:([]c1:.test.t0syms;c2:til count .test.t0syms)
// table with string column
.test.t1strs:([]c1:.test.t1strs;c2:til count .test.t1strs)

// group table on symbols
.test.g0syms:`c1 xgroup .test.t0syms
// group table on strings
.test.g1strs:`c1 xgroup .test.t1strs

// Verify that grouping and ungroupoing reproduces
//  all of the input rows - but possibly in a different order.
asc[.test.t0syms]~asc ungroup .test.g0syms
asc[.test.t1strs]~asc .finos.query.xungroup[`c1;.test.g1strs]
asc[.test.t1strs]~asc .finos.query.ungroup .test.g1strs
