// This table breaks the default CSV renderer.
//   t:([]a:1 2 3;b:(("foo";"bar");enlist"baz";("quux";`quuux;"quuuux")))
//   0N!.h.tx[`csv]t;

// The code below checks for nested types and catenates entries with a delimiter.

// Delimiter for multi-valued table cells.
.finos.html.compoundDelim:"/"

.finos.html.nestedListToStringVec:{[compoundCol]
  {[rowList]
    $[0>type rowList
     ;string rowList
     ;.finos.html.compoundDelim sv{$[10h=type x;x;string x]} each rowList]}each compoundCol}

.finos.html.stringifyCompoundCols:{[tableVal]
  // Get the name of nested cols that need converting. Leave string columns alone.
  nestedCols:exec c from meta tableVal where t in\: (" ",.Q.A except "C");
  // Functional form of "update" to yield table that can
  // be converted to CSV.
  ![tableVal;();0b;nestedCols!flip(count[nestedCols]#`.finos.html.nestedListToStringVec;nestedCols)]}


// Plug in this more lenient CSV renderer as the default.
.h.tx[`csv]:{.q.csv 0: .finos.html.stringifyCompoundCols x}


