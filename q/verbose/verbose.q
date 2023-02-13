//type-checked equivalent to ! for creating a dictionary
.finos.verbose.map:{[keylist;valuelist]
    if[not type[keylist] within 0 98h; '"keylist must be a list"];
    if[not type[valuelist] within 0 98h; '"valuelist must be a list"];
    keylist!valuelist};

//type-checked equivalent to ! for setting number of key columns in a table
.finos.verbose.setKeyColNr:{[keycount;table]
    if[not type[keycount] in -6 -7h; '"keycount must be an integer"];
    if[0>keycount; '"keycount must be nonnegative"];
    if[not type[table] in 98 99h; '"2nd argument must be a table"];
    if[99h=type[table];
        if[any not 98h=type[key table],type[value table]; '"2nd argument must be a table"];
    ];
    keycount!table};

//workaround for inability to use table syntax with security.q
.finos.verbose.table:{[keyCols;valueCols]
    if[not 0h=type keyCols; '"column name-values must be specified as a list"];
    if[not 0h=type valueCols; '"column name-values must be specified as a list"];
    if[0<count keyCols; :.z.s[();keyCols]!.z.s[();valueCols]];
    if[not 0=count[valueCols]mod 2; '"column name-value list must have even number of elements"];
    colc:count[valueCols] div 2;
    if[not 11h=type coln:valueCols[2*til colc]; '"column names must be symbols"];
    colv:valueCols[1+2*til colc];
    if[any not (type each colv) within 0 97h; '"column values must be lists"];
    flip coln!colv};

.finos.verbose.sym:{[str]
    if[not 10h=type str; '".finos.verbose.sym only works on string argument"];
    `$str};

//wrapper to allow xasc in secure gateway (raw xasc may modify table in-place)
.finos.verbose.xasc:{[sortCols;tbl]
    if[not type[sortCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.xasc expects a table"];
    sortCols xasc tbl};

//wrapper to allow xdesc in secure gateway (raw xdesc may modify table in-place)
.finos.verbose.xdesc:{[sortCols;tbl]
    if[not type[sortCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.xdesc expects a table"];
    sortCols xdesc tbl};

//wrapper to allow xkey in secure gateway (raw xkey may modify table in-place)
.finos.verbose.xkey:{[keyCols;tbl]
    if[(not () ~ keyCols) and not type[keyCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.xkey expects a table"];
    keyCols xkey tbl};

//wrapper to allow case-insenstive xasc in secure gateway (raw xasc may modify table in-place)
.finos.verbose.iasc:{[sortCols;tbl] 
    if[not type[sortCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.iasc expects a table"];
    xk:keys tbl;
    s:((),sortCols)!{$[x in "sC";(lower;y);y]}'[(0!meta[?[tbl;();0b;{![x;x]}(),sortCols]])[;`t];sortCols];
    .finos.verbose.xkey[xk] (0!tbl) iasc ?[tbl;();0b;s]};

//wrapper to allow case-insenstive xdesc in secure gateway (raw xdesc may modify table in-place)
.finos.verbose.idesc:{[sortCols;tbl] 
    if[not type[sortCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.idesc expects a table"];
    xk:keys tbl;
    s:((),sortCols)!{$[x in "sC";(lower;y);y]}'[(0!meta[?[tbl;();0b;{![x;x]}(),sortCols]])[;`t];sortCols];
    .finos.verbose.xkey[xk] (0!tbl) idesc ?[tbl;();0b;s]};

//wrapper to allow null-ignoring xasc in secure gateway (raw xasc may modify table in-place)
.finos.verbose.nasc:{[sortCols;tbl]
    if[not type[sortCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.nasc expects a table"];
    xk:keys tbl;
    s:((),sortCols)!{$[x in "cC";y;x="s";({$[null x;::;x]}';y);(^;x$0w;y)]}'[(0!meta[?[tbl;();0b;{![x;x]}(),sortCols]])[;`t];sortCols];
    .finos.verbose.xkey[xk] (0!tbl) iasc ?[tbl;();0b;s]
    };

//wrapper to allow null-ignoring xdesc in secure gateway (raw xasc may modify table in-place)
.finos.verbose.ndesc:{[sortCols;tbl]
    if[not type[sortCols] in -11 11h; '"sort columns must be symbol(list)"];
    if[not .Q.qt[tbl]; '".finos.verbose.ndesc expects a table"];
    sortCols xdesc tbl};

// unkeys a table. It is just a projection of .finos.verbose.xkey setting the first parameter to empty list
.finos.verbose.unkey: .finos.verbose.xkey[()];

.finos.verbose.priv.validateSelectArgs:{[tbl;constr;grp;stat;cnt;ord]
    if[not .Q.qt[tbl]; '".finos.verbose.select expects a table"];
    if[not 0h=type constr; '"constraints must be a general list"];
    if[not type[grp] in -11 -1 0h;
            if[not 99h=type grp; '"invalid type for groupby"];
            if[not 11h=type key grp; '"groupby must have symbol keys"];
    ];
    if[not type[stat] in -11 0h;
        if[not 99h=type stat; '"invalid type for stat"];
        if[not 11h=type key stat; '"stat must have symbol keys"];
    ];
    if[not -7h=type cnt; '"cnt must be long"];
    if[not 0h=type ord; '"ord must be a general list"];
    if[not 2=count ord; '"ord must have size 2"];
    if[not ord[0] in (<:;>:); '"first element of ord must be <: or >:"];
    if[not -11h=type ord[1]; '"second element of ord must be a symbol"];
    };

//wrapper to allow select in secure gateway (the ? operator has some overloads with side-effects)
.finos.verbose.select:{[tbl;constr;grp;stat]
    .finos.verbose.priv.validateSelectArgs[tbl;constr;grp;stat;0W;(<:;`i)];
    ?[tbl;constr;grp;stat]};

.finos.verbose.select5:{[tbl;constr;grp;stat;cnt]
    .finos.verbose.priv.validateSelectArgs[tbl;constr;grp;stat;cnt;(<:;`i)];
    ?[tbl;constr;grp;stat;cnt]};

.finos.verbose.select6:{[tbl;constr;grp;stat;cnt;ord]
    .finos.verbose.priv.validateSelectArgs[tbl;constr;grp;stat;cnt;ord];
    ?[tbl;constr;grp;stat;cnt;ord]};

.finos.verbose.selectPerfTest:{[tbl;constr;grp;stat]
    if[not 99h=type stat; '"stat must be a dictionary"];
    {[tbl;constr;grp;stcol;stexpr].Q.ts[.finos.verbose.select;(tbl;constr;grp;enlist[stcol]!enlist stexpr)][0]}[tbl;constr;grp]'[key stat;value stat]};

//wrapper to allow update in secure gateway (the ! operator has some overloads with side-effects and raw update may modify tables in-place)
.finos.verbose.update:{[tbl;constr;grp;stat]
    if[not .Q.qt[tbl]; '".finos.verbose.update expects a table"];
    if[not 0h=type constr; '"constraints must be a general list"];
    if[not -1h=type grp;
        if[not 99h=type grp; '"groupby must be boolean or dictionary"];
        if[not 11h=type key grp; '"groupby must have symbol keys"];
    ];
    if[not()~stat;
        if[not 99h=type stat; '"stat must be empty list or dictionary"];
        if[not 11h=type key stat; '"stat must have symbol keys"];
    ];
    ![tbl;constr;grp;stat]};

.finos.verbose.cond:{[cond;valTrue;valFalse]
    if[not type[cond] in 1 -1h; '".finos.verbose.cond expects boolean or boolean list in the first parameter"];
    ?[cond;valTrue;valFalse]};

.finos.verbose.columnOrder: {[col;t] (distinct (col inter cols t),(cols t) except col) # t }

.finos.verbose.columnRename:{[d;t]
    d:(d?((value d) inter cols t))! (value d) inter cols t;
    missingCols:(cols t) except value d;
    completeDict: d,missingCols!missingCols;
    :(completeDict ? (cols t)) # ?[t;();0b;completeDict]
  }

 //breaking this into multiple rows can break attached HDB/RDB
.finos.verbose.safenull:{$[type[x] in 0 77h;0=count each x;87=type x;x like "";null x]};

.finos.verbose.safestring:{$[type[x] in 10 87h;x;string x]};

///
// This converts list of general lists to list of a given type
// @param t type e.g. "c" for strings
// @param l the list
.finos.verbose.generalListVectorToTypedVector: {[t; l]
  :$[(all 0h = type each l) and 0 < count l; t$l; l];
  }    
    
///
// This converts list of general lists to list of strings
.finos.verbose.generalListVectorToStringVector: .finos.verbose.generalListVectorToTypedVector["c"];


///
//Adds summary row to the very bottom of a table
//WARNING It uses simple mathematical addition. (Don't use it in aggregates eg normalized hitrate which is not distributive for addition)
//@param t the input table (non sumable columns must be keys in other words key columns are excluded from sum)
//@param sumlabel if the input table is a keyed table then the summary row will take the value of this parameter, can pass a list for multiple keys columns
//@return the input table with an extra, summary row
.finos.verbose.addSumRow: {[t; sumlabel]
  /for keyed tables
  $[99h = type t;
    t[(count keys t)#sumlabel]: sum each flip value t;
    t,: sum each flip t];
  :t
  };


.finos.verbose.addSumCol:{[t; sumlabel]
  /for keyed tables
  $[99h = type t;
    : t ,' flip (enlist sumlabel)! enlist sum 0^value flip value t;
    : t ,' flip (enlist sumlabel)! enlist sum 0^value flip t];
  };

//Trick (op each flip) is needed to handle nulls, otherwise, null is returned for rows that has null
.finos.verbose.addAggrCol:{[t; label; op]
    t ,' flip (enlist label)! enlist op each flip value flip $[99h = type t;value t;t]
  };

///
//Adds summary column to the very end of a table. If keyed then keys are exclude from the sum, otherwise all columns will be base of the sum
//WARNING It uses simple mathematical addition. (Don't use it in aggregates eg normalized hitrate which is not distributive for addition)
//@param t the input table (non summable columns must be keys in other words key columns are excluded from sum)
//@param label name of the new column
//@return the input table with an extra, summary column
.finos.verbose.addAggrColSum:{[t; label]
  .finos.verbose.addAggrCol[t; label;sum]
  };

///
//Adds average column to the very end of a table. If keyed then keys are exclude from the avg, otherwise all columns will be base of the avg
//WARNING It uses simple mathematical average. (Don't use it in aggregates eg normalized hitrate which is not distributive for average)
//@param t the input table (non summable columns must be keys in other words key columns are excluded from avg)
//@param label name of the new column
//@return the input table with an extra, average column
.finos.verbose.addAggrColAvg:{[t; label]
  .finos.verbose.addAggrCol[t; label;avg]
  };


.finos.verbose.floatToFormattedString: {$[x=`long$x; string x; {$[(last x) ~ "0";.z.s[-1_x];x]} ltrim .Q.fmt[26;10;x]]};

.finos.verbose.symTable: {[table]
        stringCols: exec c from (meta table) where t="C";
        floatCols: exec c from (meta table) where t="f";
        nonStringOrFloatCols: (cols table) except stringCols,floatCols;
        :![table; (); 0b; (stringCols,nonStringOrFloatCols,floatCols)!(((`$) ,/: stringCols),
                                                                    ((')[`$;string] ,/: nonStringOrFloatCols),
                                                                    (')[`$;.finos.verbose.floatToFormattedString'] ,/: floatCols)];
        };

.finos.verbose.stringToSym:{[table]
                @[table;exec c from meta[table] where t="C";`$]
                };
///
// converts a table so that all columns are strings
.finos.verbose.stringTable: {[table]
  nonStringCols: exec c from (meta table) where not t="C";
  :![table; (); 0b; nonStringCols!string ,/: nonStringCols]
  }

///
// converts the key column of a keyed table to symbol
.finos.verbose.keyToSym: {[t]
  if[98h=type t;:t]; //do nothing if not keyed table
  :(`$.finos.verbose.stringTable key t)!value t
  }

///
//Fills forward each column in the table.
//Uses a scan on the string columns to accomodate any string length mismatches
.finos.verbose.safeFillsWithStrings:{[table]
    nC:where not (type each first table)=10h;
    C:where (type each first table)=10h;
    ![table;();0b;(nC!fills,/:nC),(C!({$[0=count y;x;y]}scan;)each C)]
    };

///
//Fills forward each column in the table.
//Uses a scan on the nested columns to accomodate any list length mismatches
//more robust than the function above but more time consuming
.finos.verbose.safeFillsWithLists:{[table]
    nC:where (type each first table)<0;
    C:where (type each first table)>=0;
    ![table;();0b;(nC!fills,/:nC),(C!({$[0=count y;x;y]}scan;)each C)]
    };

///
//Transpose a single keyed table (similar to what would you expect from a transposed matrix).
//@param t the input table (has to be keyed and the keys will be the new columns, original columns will be the new keys)
//@param newColName  name of the key column in the result table
//@return the transposed table
.finos.verbose.transposeGEN: {[t; newColName]
    if[0 = count t; '"Transpose with empty table"];

    //works on single columnkeyed table
    newCols: first value flip key t;
    transposedData : flip value flip value t;
    flip[enlist[newColName]!enlist cols value t]! flip [newCols!transposedData]
 };

///
//Projection of the .finos.verbose.transposeGEN keeping the key column name in the result table
//@param t the input table (has to be keyed and the keys will be the new columns, original columns will be the new keys)
//@return the transposed table
.finos.verbose.transpose:{[t] .finos.verbose.transposeGEN[t; first keys t] };

///
// same as .finos.verbose.transpose but it converts the key set to symbols thus can handle e.g. keys of type date or string.
.finos.verbose.transposeSafe: {[t] .finos.verbose.transpose .finos.verbose.keyToSym t }

////
// Drops columns that contain null values for all elements
.finos.verbose.dropFullNullCols: {[t]
  :(where all each .finos.verbose.safenull flip t) _ t;
  }

////
// Drops elements of a dictionary that give back nulls (if value is list, only nulls)
// string and dict values are excluded from the check
.finos.verbose.dropNullsFromDict: {[x]
  xx:((key x) where ({(type x) in 0 99h} each value x))_x;
  ((key xx) where all each value .finos.verbose.safenull xx)_x
  }

////
// Drops rows that contain null values for any key element
.finos.verbose.dropNullKeyedRows: {
    delete from x where any .finos.verbose.safenull each flip key x
 };

////
// Prefix all non keyed column names with a string - useful for lj
//@param prefix string
//@param t keyed table
.finos.verbose.prefixValueCols: {[prefix;t]
    $[0=count cols value t; t; ((keys t),`$prefix,/: string cols value t) xcol t]
 };

///
// Returns a list of timestamps that uniformly cover the min[x] to max[x] time interval with gran second granularity
//@param gran the granularity in seconds
//@param x a list of timestamps
//@return a list of timestamps that uniformly cover the min[x] to max[x] time interval with gran second granularity
.finos.verbose.timesplit: {[gran;x] min[x]+`timespan$(gran*`float$`timespan$00:00:01) * til floor reciprocal[gran] * reciprocal[`float$`timespan$00:00:01] *`float$max[x] - min[x] };

//apply fun1 on dates before cut date, fun2 on starting from cut date, with respect to start date and end date
//fun1 is exclusive on cut date, fun2 includes it
//both fun1 and fun2 have to be a function with 2 date arguments
.finos.verbose.sliceByDate: {[sd;ed;cd;fun1;fun2] 
	  $[(sd<cd);fun1[sd;min[ed,cd-1]];()],$[(ed>cd-1);fun2[max[sd,cd];ed];()]
 };

//by default these are identity, specify the timezone parameter to have these overwritten in setup.q
.finos.verbose.ltime:(::);
.finos.verbose.gtime:(::);

//moves the constraint which only affects fields specified in the "pre" parameter to the front in "constrList"
.finos.verbose.reorderConstrList: {[pre;constrList]
    first value flip `nr xasc ![([] constr: constrList; nr: (1 + count constrList) + til count constrList);
            enlist (min';(in;(.finos.verbose.collectFields';`constr);enlist pre));
            0b;
            .istat.FIELDAS[`i;`nr]]};

//reverse value cols of table (reverse all if non keyed)
.finos.verbose.reverseValueCols: {[t]
   k:keys t;
   if[0=count k;:(reverse cols t) xcols t];
   k xkey (k,reverse cols value t) xcols () xkey t
 };
 
.finos.verbose.nestedpivot: {[t;string_separator]
   if[not 99h=type t; '"not keyed table"];
   grp:cols key t;
   if[2>count grp; '"at least 2 key cols needed"];
   .finos.verbose.pivotUnsafe (count grp)!.finos.verbose.select[.finos.verbose.unpivot[`stat;`value;.finos.verbose.keyToSym t];();0b;.istat.FIELD[-1_grp],.istat.FIELDAS[(`$;({raze (string y), x, string z}[string_separator]';last grp;`stat));`dummy],.istat.FIELD[`value]]
 };


// Rearrange columns given a predefinied ordering for a table. Leave key columns for keyed tables.
// The given ordering is supposed to contain all symbol which may appear in domain of the your table/application.
// (ordered list can be greater then the existing columns)
// Columns not specified in ordering are sorted using asc (<- should be revised during code review)
//
//@param o symbol list specifying your domain specific ordering
//@param t the table which columns should be rearranged
//
.finos.verbose.fixColumnOrderGEN: {[o;t]
      covered: $[99h ~ type t;                      // if keyed table
                    keys[t], o inter cols value[t]; // leave keys untouched sort value cols against ordering
                 98h ~ type t;                      // if not keyed table
                    o inter cols t;                 // sort all cols against ordering
                  '"invalid branch"
                ];
      leftOut :asc cols[t] except covered;          // rest of cols should be ascending
      :keys[t] xkey (covered,leftOut) xcols () xkey t; // covered cols as ordered then remaining cols in ascending order then restate keys
 };

// Rearrange row given a predefinied ordering for a keyed table.
// More then one key columns isallowed but all of them has to be symbol. (<- should be revised during code review)
// The given ordering is supposed to contain all symbol which may appear in domain of the your table/application.
// (ordered list can be greater then the actual distinct values in all key column)
// Key sets not specified in ordering are sorted using asc (<- should be revised during code review)
//
//@param o symbol list specifying your domain specific ordering
//@param t a keyed table which rows should be rearranged based on the ordering of the keys
//
.finos.verbose.fixRowOrderGEN: {[o; t]                                                   // t has to be a keyed table
    orderCols: (),`$"ordering_",/: string  keys t;                            // figure out how many helper columns needed
    t:  ![t; (); 0b; orderCols!{[o; col] (?;enlist o; col) }[o] each keys t]; // extend t with helper columns
    t:  orderCols xasc t;                                                     // apply ordering
    : ![t; ();0b; orderCols];                                                 // remove helper columns
 };

// Apply both column and row ordering on a keyed table using the predefined order.
//
// Please check .finos.verbose.fixColumnOrderGEN and .finos.verbose.fixRowOrderGEN for more details.
//
//@param o symbol list specifying your domain specific ordering
//@param t a keyed table which rows should be rearranged based on the ordering of the keys
//
.finos.verbose.fixOrdersGEN:{[o; t]
    .finos.verbose.fixColumnOrderGEN[o] .finos.verbose.fixRowOrderGEN[o;t]
 };

///
// does asof aggregation of a value keyed by a certain column
// Let us assume that we have a table that contains columns time, sym
// and a field that would would like to sum for each sym.
// The problem is that the value is available for different time stamps.
// This function bring the input to a common key base (generally common date and time field)
// and applies the aggregate function (e.g. addition).
// This function can be used for example to calculate the midprice of and index (weighted set of instruments).
//
.finos.verbose.aggregateFieldValuesAsOf: {[t; k; p; v; colname; binop]
  piv: fills .ms.pivot.pvtfw[t; k; p; v; (); ()];
  c: (cols piv) except cols t;

  // if single key value just rename column, otherwise apply binary operator
  // I am sure the exists a more elegant solution.
  colCalculus: $[1 = count c;
    first c;
    enlist (first c) {(x; z ;y)}[binop]/ 1 _ c];

  :?[piv; (); 0b; (k, colname)!k, colCalculus];
  }

///
// "n" seconds window before t; Implies [t-n Seconds; t] time window.
// @param n Number of seconds
// @param t Time field - it will be used in wj
// @return pairs of time (indicating the interval)
.finos.verbose.nSecWinBefT:{[n;t] (t - n*1000;t)};

///
// "n" seconds window after t; Implies [t t+n seconds] time window.
.finos.verbose.nSecWinAftT:{[n;t] (t; t + n*1000)};
///
// "n" minutes window before t; Implies [t-n minutes; t] time window
.finos.verbose.nMinWinBefT:{[g;n;t] g[60*n;t]}[.finos.verbose.nSecWinBefT];
///
// "n" minutes window after t; Implies [t t+n minutes] time window.
.finos.verbose.nMinWinAftT:{[g;n;t] g[60*n;t]}[.finos.verbose.nSecWinAftT];
///
// "n" hours window before t; Implies [t-n hours; t] time window
.finos.verbose.nHrWinBefT:{[g;n;t] g[3600*n;t]}[.finos.verbose.nSecWinBefT];
///
// "n" hours window after t; Implies [t t+n hours] time window.
.finos.verbose.nHrWinAftT:{[g;n;t] g[3600*n;t]}[.finos.verbose.nSecWinAftT];

// filter out commas in column values, e.g. for QlikView
.finos.verbose.dropCommas:{[t]
  :flip {[col]$[(10h=type first col) and 0h=type col;ssr[;",";""]'[col];11h=type col;`$ssr[;",";""]'[string col];col]} each flip t
  };

.finos.verbose.asyncQuery:{[query;callbackFunName;callbackId]
    res:try[{(`success;.z.pg x)}; enlist query;{(`error;x)}];
    neg[.z.w](callbackFunName;callbackId),res;
    neg[.z.w][::];
    };

.finos.verbose.localTableMeta:{[table]
    if[not .Q.qt table; '".finos.verbose.localTableMeta: expects table"];
    meta table};

//security-safe version of try
.finos.verbose.try:{[fun;params;errorHandler]
    if[100h<>type fun; '"fun must be a lambda"];
    if[100h<>type errorHandler; '"errorHandler must be a lambda"];
    if[not type[params] within 0 20h; '"params must be a list"];
    try[fun;params;errorHandler]};

///
// Escape a string to make it usable as a variable identifier
// Useful when you use variable names based on data values that may contain special characters (space, dash etc.)
// @param x String
.finos.verbose.escapeID:{conv:-11h=type x;$[conv;`$;::]ssr[.h.hug[.Q.an except "_"]$[conv;string x;x];"%";"_"]};

.finos.verbose.numToOrdinalString: ((1 + til 11)!("First"; "Second"; "Third"; "Fourth"; "Fifth"; "Sixth"; "Seventh"; "Eighth"; "Ninth"; "Tenth";"Eleventh"));