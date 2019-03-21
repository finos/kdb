//DBA (kdb+ datastore) utilities to manage partitioned and splayed tables.
//Originally based on open source utils from code.kx.com

///
//Get all the partitions in a HDB.
//Support all valid types.
//@param path to database (hsym)
//@return empty list if no partitions are found
.finos.dba.getParts0:{[db]
    if[()~l:key db;'(string db),": No such file or directory"];
    f:{[db] d:key db;d@where d like "[0-9]*"};
    r:$[`par.txt in key db;
    raze f'[hsym each `$read0` sv db,`par.txt];
    f db];
    if[0=count r;:r];
    c:.finos.dba.partCastChar first r;
    c$string r}

///
//Get all the partitions in a HDB.
//Support all valid types.
.finos.dba.getParts:{[db]
  r:.finos.dba.getParts0 db;
  if[0=count r;'"No partitions found at: ",string db];
  r}

///
//Load a splayed table as a dictionary.
//Normally, `:partitionDir@`tableName would work, but for directories
// that have dotfiles that are lexicographically earlier than .d,
// assumptions are violated and q fails to load the table.
//Also, tables with uneven column lengths can't be flipped.
//@return table
.finos.dba.loadSplayedTableDict:{[tableHsym]
    .finos.tc2.argMatch[.z.s;enlist tableHsym;enlist `:/path/to/table];
    files:key tableHsym;                 / Get filenames in tableDir.
    if[not `.d in files;
        '`notTableDir];  / Ensure there's a .d file.
    colNames:tableHsym`.d;               / Read the .d file.
    /Return map-on-demand or map-immediate depending on trailing "/".
    colVals:$["/"~last string tableHsym;
        x;
        @[tableHsym@;;()]each colNames]; / Return () if cannot read col.
 colNames!colVals}

///
//Matching column lists like wantTypes~haveTypes yields false positives
// for empty tables that have compound columns since the empty column
// would have a type of " " rather than "C".
//@param wantTypes List of char.
//@param haveTypes List of char.
//@param cnt Number of rows in the table.
//@return True if wantTypes~haveTypes or all " " columns are compound columns in wantTypes.
.finos.dba.colTypeMatcher:{[wantTypes;haveTypes;cnt]
    matched:wantTypes~haveTypes;
    if[matched|0<cnt;
        :matched];
    if[count[wantTypes]<>count haveTypes;
        :0b];
    haveTypesBlank:haveTypes=" ";
    blankPos:where haveTypesBlank;         / Positions with relaxed matching.
    nonblankPos:where not haveTypesBlank;  / Positions with exact matching.
 (wantTypes[nonblankPos]~haveTypes[nonblankPos]) & all wantTypes[blankPos] in .Q.A}

///
//"Denumerate" (i.e. resolve enumerations in) object x (recurse if necessary)
//@param x Object to process (simple type, list, dict or table)
//@return "Denumerated" object.
.finos.dba.priv.help,: enlist".finos.dba.denum[list/table/dict]";
.finos.dba.denum:{[x]
    $[0=t:abs type x;
            .z.s'[x];
        t<20;
            x;                        / built-in-types
        t<=77;
            $[-11h=type key enumName:key x;
                value x;      / enumeration
                '"sym list not loaded: ",string enumName];
        t<98;
            .z.s'[x];                 / compound list
        t=98;
            @[x;cols x;.z.s];         / table
        t=99;
            !/[.z.s'[(key;get)@\:x]]; / dict
            '`unknownType]}

///
//Section: Datastore generation functions
//Examples:
//splay trade table, enumerate all symbol cols to `sym and use `sym column as parted column
//> splayToPartition[`:/d/d1/data;2009.01.01;`sym;`trade]
//splay trade table as `prints, enumerate all symbol cols to `sym and use `sym column as parted column
//> splayDataToPartition[`:/d/d1/data;2009.01.01;`sym;`prints;trade]
//splay trade table, enumerate named `foo`bar symbol columns individually all others against
//`sym, sort by `foo and apply parted attribute, do not reorder columns
//> splayToPartition[`:/d/d1/data;2009.01.01;(`foo`bar;`foo;`);`trade]
//snapshot and copy symbol files and repoint all files to a new a new dated directory
//copies `:/d/d1/data/sym to `:/d/d1/snapshot/sym.2009.01.01 (today's date) and
//creates a symlink from `:/d/d1/data/sym to the snapshot
//> snapshotSym[`:/d/d1/data;`:/d/d1/snapshot]
.finos.dba.priv.help,: "--- Datastore production functions ---";

///
//Load (reload) all sym files
//@param db DB root path (hsym)
//@return list of sym variables
.finos.dba.loadSyms:{[db]
    db:.finos.dba.pathAsHsym db;
    /find all sym files
    s:f where (f:key db) like string[.finos.dba.priv.SYMPREFIX],"*";
    /load all sym files
    s set'get each ` sv'db,'s}

