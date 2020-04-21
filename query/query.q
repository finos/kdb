///
// Helper function to flip table rows presented as dictionaries.
// Flip extends atoms automagically, but strings are treated
//  as compound lists of characters which won't flip due to
//  inconsistent length with other compound columns.
// @param strCols List of symbols specifying the columns to be treated as strings.
// @param d Dictionary of column vectors.
// @return Flipped row dictionary to be used as a segment of new table.
.finos.query.xflipDict:{[strCols;d]
  if[99h<>type d; '"d must be a dictionary from a table row"];
  if[11h<>abs type strCols; '"strCols must be a symbol or list thereof"];
  strCols,:();         / Ensure strCols is a list.
  nsc:strCols _ d;     / Non-string column vectors.
  errMsg:"Failed to flip non-string columns. "
        ,"Check that all string columns were specified.  Error: ";
  // Flip the non-string column vectors into a table.
  r:@[flip;nsc;{[errMsg;err]'errMsg,-3!err}[errMsg;]];
  // Replicate string values to match length of r.
  sc:strCols!(count[r]#enlist@)each value strCols#d;
  // Then put it back into a table structure and paste to r.
  // Put columns back in original order.
  key[d]xcols r,'flip sc
 }

///
// Treat columns named in "strCols" as strings that are not
//  to be ungrouped.  Useful for tables that have strings for
//  GUID columns.
// @param strCols List of symbols specifying the columns to be treated as strings.
// @param t Table to be ungrouped.
// @return Table that has had nested subvectors flattened out into
//           multiple rows.
.finos.query.xungroup:{[strCols;t]
  if[`~strCols; : ungroup t];
  $[count t:()xkey t
   ;raze .finos.query.xflipDict[strCols;]each t
   ;t]
 }


///
// Ungroup a table that might use vectors of characters as strings.
// Use .finos.query.xungroup[...] for finer control.
// @param t Table to be ungrouped.
.finos.query.ungroup:{[t]
  strCols:exec c from meta t where t="C";
  $[count strCols
   ;.finos.query.xungroup[strCols;t]
   ;ungroup t]}


