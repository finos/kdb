# <a id="HDBWellFormedness"></a>[HDB Well-Formedness](#user-content-hdbwellformedness)

## <a id="Introduction"></a>[Introduction](#user-content-introduction)

An HDB is a collection of q data and code in a directory. Its structure is subject to several constraints, the violation of any of which may cause errors, performance problems, or undefined behavior.

### <a id="Version"></a>[Version](#user-content-version)

This work documents the behavior of q 3.6 2019.06.05.

### <a id="Heuristic"></a>[Heuristic](#user-content-heuristic)

Intuitively, we may say (at least) the following of operations on a well-formed HDB:

 * The command `\l HDB` succeeds.

 * The command ``count each get each tables` `` succeeds.

 * The command ``meta each tables` `` succeeds.

 * The command ``{select from x}each tables` `` would succeed if sufficient memory were available.

The following is an attempt to document necessary and sufficient conditions for these properties to hold for any given HDB.

### <a id="Approach"></a>[Approach](#user-content-approach)

The approach taken here is, for the HDB and each of its possible elements, to give each of the following:

 * recognition and use by q
 
 * a brief definition
 
 * further constraints
 
 * any concluding notes

### <a id="Definitions"></a>[Definitions](#user-content-definitions)

Unless otherwise specified:

 * "file" refers to a plain file or to a symbolic link pointing (ultimately) at a plain file, but never to a directory

 * "directory" refers to a directory or to a symbolic link pointing (ultimately) at a directory

 * "first" refers to the first item in the directory listing returned by `key` (or to the first such item satisfying some constraint). This is equivalent to the first such item in the directory listing returned by `system"LC_ALL=C ls"`, i.e. the first in ASCII byte-by-byte lexicographic order.

## <a id="Elements"></a>[Elements](#user-content-elements)

An HDB is a directory containing only any<sup>[1](#user-content-noteemptyhdb)</sup> of the following elements:

 * Files or directories whose names end in a dollar sign (`x like"*$"`) ([staging files](#user-content-stagingfiles))

 * [Code](#user-content-code)

 * [Serialized q data](#user-content-serializedqdata)

 * [Splayed tables](#user-content-splayedtables)

 * [Partitions](#user-content-partitions) ***or*** the file `par.txt` pointing to [segments](#user-content-segments)

 * A directory named [`html`](#user-content-html)

 * [Other directories](#user-content-onnesting)

Its data is loaded into the global namespace.

The presence of any other files is an error. In particular, it is an error for an HDB to contain any files which are not code or data or any directories whose names end in extensions of exactly one letter. (This includes "unix-invisible" files whose names begin with dots, such as the `.__nfs*` files caused by certain networked filesystem problems, or the `.DS_Store` files automatically created on many Mac OS X systems.)

### <a id="StagingFiles"></a>[Staging Files](#user-content-stagingfiles)

Each file whose name ends in a dollar sign (`x like"*$"`) is a q staging file (used for safe updating of a symfile, etc.) and is ignored.

Each directory whose name ends in a dollar sign is also ignored.

This rule overrides all others.

### <a id="Code"></a>[Code](#user-content-code)

Each file whose name ends in an extension of exactly one letter (`x like"*.?"`) is code. If the argument given to `q` or to `\l` is not "`.`", such files are executed in lexicographic order by name after all other elements have been loaded; otherwise they are ignored.

As q is currently shipped, it is an error for such a file to have an extension other than `.q` or `.k`, as these are the only languages supported by default.<sup>[2](#user-content-otherlanguages), [3](#user-content-notebadcode)</sup>

### <a id="SerializedqData"></a>[Serialized q Data](#user-content-serializedqdata)

Each file whose name does not end in an extension of exactly one letter or the string `"#"` or `"##"` is serialized q data and is loaded into a global variable with the same name as the file.

It is an error for such a file not to be q data readable with `get`.

Each file whose name ends in the string `"#"` or `"##"` is related to a file whose name is otherwise identical but does not end in any `"#"` characters. It is an error for such a file not to exist if it was created when its related non-`#` file was created. It is an error for such a file to exist in the absence of its related file. TODO find a name for # files

### <a id="SplayedTables"></a>[Splayed Tables](#user-content-splayedtables)

Each directory whose name does not start with a digit (`not x like"[0-9]*"`), whose name does not end in an extension of exactly one letter, and which contains a file named `.d` is a splayed table and is loaded into a global variable with the same name as the directory.

A splayed table is a directory containing a file named `.d` which is a serialized vector of symbols containing the names of the columns of the table; for each column so named, the directory also contains a file of that name which is a serialized vector or list. For each column so named that is a list, the directory may also contain a file of that name with the character `"#"` appended. Any other files in the directory are ignored.

It is an error for `.d` not to be a serialized vector of symbols or for any of the files named in it not to exist or not to be serialized vectors or lists.

It is an error for the files named in `.d` to be vectors or lists of differing lengths, except in limited conditions: a query will succeed if, of the columns it accesses, none of those which are longer than the minimum length among those columns has the attribute `u`, `p`, or `g`.

It is an error causing performance problems for any of the files named in `.d` to be vectors of symbols (as opposed to enumerated vectors of symbols).

It is an error for any of a splayed table's column files to be enumerated against an enumeration which is not in the HDB.

### <a id="Partitions"></a>[Partitions](#user-content-partitions)

Each directory whose name starts with a digit is a partition. The tables within such partitions are loaded into global variables with the same names as those tables.

An HDB which contains partitions is a partitioned HDB.

The partitioning field of a partitioned HDB is determined by the name of the first partition: if it is 10, 7, or 4 characters long, the field is `` `date``, `` `month``, or `` `year``, respectively; otherwise it is `` `int``.<sup>[4](#user-content-noteintlong), [5](#user-content-noteintyear)</sup>

A partition is a directory whose name starts with a digit and which contains only splayed tables.

It is an error for an HDB which contains partitions to contain the file `par.txt`.

It is an error for a partition to contain anything other than splayed tables.

It is an error for a partition to exist with a name which produces a null value when cast to the partitioning field of its HDB.

It is an error for all partitions not to be of the same [schema](#user-content-onschemas): for each table present in any partition, it must exist with the same schema in all partitions.<sup>[6](#user-content-note.q.bv)</sup>

Note that it is ***not*** an error for all partitions to be empty.

### <a id="Segments"></a>[Segments](#user-content-segments)

The file `par.txt` is a plain-text file containing the path of at least one segment, at least one of which contains at least one partition.

An HDB which contains a `par.txt` file is a both a segmented HDB and a partitioned HDB.

An HDB which contains only partitions and is referred to by a `par.txt` file in another HDB is a segment of that HDB.

The partitioning field of a segmented HDB is the partitioning field of its first non-empty segment, where segments are ordered by their order in `par.txt`.<sup>[7](#user-content-noteintyearseg)</sup>

It is an error for the `par.txt` file of a segmented HDB to be empty.

It is an error for a segmented HDB to (directly) contain partitions.

It is an error for a segment of an HDB to be a descendent directory of that HDB.

It is ***not*** an error for ***a segment*** of an HDB to be empty; it ***is*** an error for ***all segments of an HDB*** to be empty.

It is an error for a segment of an HDB to contain anything other than partitions.

It is an error for a segment of an HDB to contain any directory whose name produces a null value when cast to the partitioning field of that HDB. In particular, it is an error for all segments of an HDB not to have the same partitioning field.

It is an error for all segments of an HDB not to be of the same [schema](#user-content-onschemas): for each table present in any partition of any segment of an HDB, it must exist with the same schema in all partitions of all segments of that HDB.<sup>[6](#user-content-note.q.bv)</sup>

Note that it is ***not*** an error for a given partition to exist in more than one segment of an HDB (i.e. for the segment-to-partition mapping to be many-to-many, not one-to-many). If any partition exists in more than one segment of an HDB, `.Q.u` is set to `0b` when that HDB is loaded, and the HDB is a non-orthogonally-segmented HDB. Queries executed on such HDBs may need to differ from those executed on orthogonally-segmented HDBs in order to return a result of the expected rank, and may also suffer performance problems; further analysis of such HDBs is outside the scope of this work.<sup>[8](#user-content-notemultisegment)</sup>

### <a id="HTML"></a>[HTML](#user-content-html)

A directory named `html` is used by the q web server and contains arbitrary content.

## <a id="ConcludingNotes"></a>[Concluding Notes](#user-content-concludingnotes)

### <a id="OnSchemas"></a>[On "Schemas"](#user-content-onschemas)

Strictly speaking, the "schema" of a table as used in [Partitions](#user-content-partitions) and [Segments](#user-content-segments) above is defined only by the presence of the set of column files required to represent the columns of that table. In particular, column type is not verified, nor is the presence of column attributes. Nonetheless, other inconsistencies may cause errors, performance problems, or undefined behavior.

If the columns of a table have inconsistent types (this includes being enumerated against inconsistent enumeration lists) among partitions, undefined behavior may result.

If the columns of a table have inconsistent attributes among partitions, performance problems may result.

### <a id="OnNesting"></a>[On Nesting](#user-content-onnesting)

More complex nested structures are possible; these are created by the presence of directories in an HDB which do not contain `.d` files or by the presence of partitioned tables whose names contain dots. This data is loaded into dictionaries in the global namespace; further analysis of these features is outside the scope of this work.

* * *

## <a id="Footnotes"></a>[Footnotes](#user-content-footnotes)

1. <a id="noteEmptyHDB"></a>An empty directory is a valid HDB.

2. <a id="otherLanguages"></a>Other available languages include [`s`](https://github.com/KxSystems/kdb/blob/master/s.k), an implementation of ANSI SQL, and `p`, which is supported when [embedPy](https://github.com/KxSystems/embedPy) is loaded.

3. <a id="noteBadCode"></a>It is of course also an error for such a file not to be valid code in its indicated language, but this is not precisely a *structural* error in the HDB.

4. <a id="noteIntLong"></a>The name `` `int`` is a legacy from prior versions of q: the global vector `` `int`` and the `` `int`` column of partitioned tables in an `` `int``-partitioned HDB are actually of type `` `long``.

5. <a id="noteIntYear"></a>An HDB meant to be partitioned by `int` is loaded as `year`-partitioned if its first partition's name is a four-digit number. A dummy partition named `0` or `1` (containing [schema-conformant](#user-content-onschemas), but empty, tables) prevents this.

   (Conversely, a `year`-partitioned HDB dealing with any years before AD 1000, in the unlikely event that any such HDB exists, is loaded as `int`-partitioned; zero-padding its first partition to four digits prevents this. Similarly, a `year`-partitioned HDB dealing exclusively with years after AD 9999 is loaded as `int`-partitioned; a dummy partition named `1000` prevents this.)

6. <a id="note.Q.bv"></a>This requirement may be relaxed by invoking [`.Q.bv`](https://code.kx.com/v2/ref/dotq/#qbv-build-vp), but that option has certain limitations; e.g., queries using linking columns fail if they would otherwise rely on the functionality it activates. Further discussion is outside the scope of this work.

7. <a id="noteIntYearSeg"></a>The considerations in <sup>[5](#user-content-noteintyear)</sup> also apply here.

8. <a id="noteMultiSegment"></a>Support for non-orthogonal segmentation originates in constraints on prior versions of q that are no longer applicable; there are very few good reasons for using this feature in modern versions of q, and many reasons for avoiding it.
