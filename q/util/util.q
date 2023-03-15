// General-purpose utility functions.

///
// read0, but compatible with non-seekable files (fifos, /proc, etc.).
// @param x file symbol
// @return A list of strings containing the contents of the file.
// @see read0
.finos.util.read0f:{r:{y,read0 x}[h:hopen`$":fifo://",1_string x]over();hclose h;r}

///
// read1, but compatible with non-seekable files (fifos, /proc, etc.).
// @param x file symbol
// @return A byte vector containing the contents of the file.
// @see read1
.finos.util.read1f:{r:{y,read1 x}[h:hopen`$":fifo://",1_string x]over();hclose h;r}

.finos.util.compose:('[;])/

// create a list. e.g. list(`a;1) -> (`a;1)
// allows a trailing delimiter, e.g.
// list(
//     `a;
//     1;
//     )
.finos.util.list:{$[104h=type x;1_-1_get x;x]}

// create a dictionary. e.g. dict (1;2;3;4) -> 1 3!2 4
.finos.util.dict:{(!) . flip 2 cut .finos.util.list x}

// create a table. e.g. table[`x`y;(1;2;3;4)] -> ([]x:1 3;y:2 4)
.finos.util.table:{flip x!flip(count x)cut .finos.util.list y}

// log stubs
.finos.log.critical:{-1"CRITICAL: ",x;}
.finos.log.error   :{-1"ERROR: "   ,x;}
.finos.log.warning :{-1"WARNING: " ,x;}
.finos.log.info    :{-1"INFO: "    ,x;}
.finos.log.debug   :{-1"DEBUG: "   ,x;}

.finos.util.shr :{0b sv x xprev 0b vs y}     / right shift
.finos.util.xor :{0b sv (<>/)   0b vs'(x;y)} / XOR
.finos.util.land:{0b sv (&).    0b vs'(x;y)} / AND
.finos.util.lnot:{0b sv not     0b vs x}     / NOT

.finos.util.crc32:{.finos.util.lnot(.finos.util.lnot"i"$x){.finos.util.xor[.finos.util.shr[8]y]x .finos.util.xor[.finos.util.land[y]255i]0x0 sv 0x000000,"x"$z}[{8{$[x mod 2i;.finos.util.xor -306674912i;::].finos.util.shr[1]x}/x}each"i"$til 256]/y}

// Run and log garbage collection.
.finos.util.free:{[].finos.log.debug"freed ",(string .Q.gc[])," bytes";}

// Date from year/month/day.
.finos.util.ymd:{"D"$"."sv"0"^-4 -2 -2$string(x;y;z)}'

// Convert epoch seconds to (global) timestamp.
// @param x number or number vector
// @return timestamp or timestamp vector
.finos.util.timestamp_from_epoch:{"p"$("j"$1970.01.01D)+1000000000*x}

// Attempt to execute a monadic function.
// Can be replaced with {(1b;x y)} for debugging.
// @param x monadic function
// @param y arg
// @return pair: (1b;result) or (0b;error)
.finos.util.try:{@[(1b;)x@;y;(0b;)]}

// Print progress, with peach and try-catch.
// The weight function is used to measure progress more accurately when
//  different arguments will take significantly different amounts of time.
//  When this is not the case, pass a constant function (e.g. {1}).
// E.g. to (re/de)compress files, set/unset .z.zd and pass x as hcount, y
//  as {x set get x}, and z as the files.
// @param x monadic function: weight (e.g. hcount, {1}, etc.)
// @param y monadic function
// @param z list: args for y
// @return dict: z!@[(1b;)y@;;(0b;)]peach z
.finos.util.progress:{
  f:{[s;f;a;w;i]
    eta:{x+(abs type e)$(e:y-x)%z};
    dll:{" "sv(key x){": "sv(string x;$[10<>type y;string;]y)}'get x};
    progper:{
      paren:{"(",x,")"};
      prog:{"/"sv(neg count string y)$string(x;y)};
      per:{.Q.fmt[6;2;100*x],"%"};
      " "sv(prog[x;y];paren per x%y)};
    .finos.log.debug dll`now`position`work`elapsed`eta!(
      p;
      progper[i+1;count a];
      progper[w i;last w];
      p-s;
      eta[s;p:.z.P;(w i)%last w]
      );
    .finos.util.try[f]a i};
  z!f[.z.P;y;z;w:sums x peach z]peach til count z}
