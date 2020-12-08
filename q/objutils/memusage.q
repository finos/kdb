// Functionality to return approx. memory size of kdb+ objects


// half size for 2.x
.finos.objutils.version:.5*1+3.0<=.z.K;

// set the pointer size based on architecture
.finos.objutils.ptrsize:$["32"~1_string .z.o;4;8];

.finos.objutils.attrsize:{.finos.objutils.version*
  // `u#2 4 5 unique 32*u
  $[`u=a:attr x;32*count distinct x;
    // `p#2 2 1 parted (8*u;32*u;8*u+1)
    `p=a;8+48*count distinct x;
    0]
  };

// (16 bytes + attribute overheads + raw size) to the nearest power of 2
.finos.objutils.calcsize:{[c;s;a] `long$2 xexp ceiling 2 xlog 16+a+s*c};

.finos.objutils.vectorsize:{.finos.objutils.calcsize[count x;.finos.objutils.typesize x;.finos.objutils.attrsize x]};

// raw size of atoms according to type, type 20h->76h have 4 bytes pointer size
.finos.objutils.typesize:{4^0N 1 16 0N 1 2 4 8 4 8 1 8 8 4 4 8 8 4 4 4 abs type x};

.finos.objutils.threshold:100000;

// pick samples randomly accoding to threshold and apply function
.finos.objutils.sampling:{[func;obj]
  $[.finos.objutils.threshold<c:count obj;func@.finos.objutils.threshold?obj;func obj]};

// scale sampling result back to total population
.finos.objutils.scaleSampling:{[func;obj]
  .finos.objutils.sampling[func;obj]*max(1;count[obj]%.finos.objutils.threshold)
  };

// return full variable names
.finos.objutils.varnames:{[ns;vartype;shortpath]
  vars:system vartype," ",string ns;
  `$$[shortpath and ns in `.`.q;"";(string ns),"."],/:string vars
  };

// return all non-single character namespaces in current process
.finos.objutils.getall:{a:(enlist enlist "."),".",/:string key `;`$(a where 2<count each a)};

.finos.objutils.objsize:{
  // count 0
  if[not count x;:0];
  // flatten table/dict into list of objects
  x:$[.Q.qt x;(key x;value x:flip 0!x);
    99h=type x;(key x;value x);
    x];
  // special case to handle `g# attr
  // raw list + hash
  if[`g=attr x;x:(`#x;group x)];
  // atom is fixed at 16 bytes, GUID is 32 bytes
  $[0h>t:type x;$[-2h=t;32;16];
    // list & enum list
    t within 1 76h;.finos.objutils.vectorsize x;
    // exit early for anything above 76h
    76h<t;0;
    // complex = complex type in list, pointers + size of each objects
    // assume count>1000 has no attrbutes (i.e. table unlikely to have 1000 columns, list of strings unlikely to have attr for some objects only
    (d[0] within 1 76h)&1=count d:distinct (),t;.finos.objutils.calcsize[count x;.finos.objutils.ptrsize;0]+"j"$.finos.objutils.scaleSampling[{sum .finos.objutils.calcsize[count each x;.finos.objutils.typesize x 0;$[1000<count x;0;.finos.objutils.attrsize each x]]};x];
    // other complex, pointers + size of each objects
    .finos.objutils.calcsize[count x;.finos.objutils.ptrsize;0]+"j"$.finos.objutils.scaleSampling[{[f;x]sum f each x}[.z.s];x]]
  };

// get sizes of all variables within a specified namespace (enter .finos.objutils.allsizes[`] to return all namespaces)
.finos.objutils.allsizes:{
  $[x~`.;
  vbl:key `.;
  [vbl:raze .finos.objutils.varnames[;;0b] .' .finos.objutils.getall[] cross "vb";
  $[x<>`;
    [x:raze "*",string[x],".*";vbl:vbl where string[vbl] like x];
    vbl:vbl,key `.
  ]]];
  tab:update sizeMB:sizeMB%2 xexp 20 from update sizeMB:{.finos.objutils.objsize[value x]}each vbl from ([]vbl);
  `sizeMB xdesc tab
  };