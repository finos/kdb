Q Coding Guidelines
===================

This is a collection of guidelines and best practices for `q`.

Introduction
------------

Why have code conventions? It should be clear that readability of code
is essential for code maintainability. This applies to all software
languages, but becomes even more important in languages with such high
density of notation as `q`.

### Acknowledgements

This initial release of these guidelines are based on notes and training
materials authored by Jeff Borror, Charlie Skelton's (kx.com) guidelines
and Stevan Apter's [Remarks on Style](http://www.nsl.com/papers/style.pdf).

### Motivation

-   Code is:
    -   written once
    -   modified 10 times
    -   read 100 times
-   Write for those who come after you

### Q coding goals

-   short vs simple:
    -   Simple problems usually have simple solutions in q
    -   Fewer operators often but not always means simpler and better
    -   Code count should not be the primary metric of q code goodness
-   Q coding strategy:
    -   *Find a solution that works, then look for simpler solutions. If
        performance is critical, test and pick the solution with the
        quickest execution.*
-   Go with the flow:
    -   Use data constructs and idioms of `q`
    -   Do not impose constructs from other languages
    -   Use vector operations whenever reasonable
    -   Do not make your q code look like: C, Java, Perl, SQL, or ...

File Names
----------

-   suffixes: `q` scripts must have the `.q` extension
-   names: `q` scripts should use alphanumeric names without whitespace

File Organisation
-----------------

-   beginning comments: use a comment block that lists Perforce keywords
    for filename, version, date and author info as well as a copyright
    notice
-   for batch processes, define a main function and invoke via protected
    evaluation to exit with a suitable return code (kdb always
    returns 0)

```
main:{[parms]
  / body of script
  }
@[main;parms;{.ms.log.error "Error: ",x;exit 1}];
exit 0;
```

Naming Conventions
------------------

-   names should be easy to type and read
-   **avoid** underscores `_`
    in names and expressions
    -   `_` is an operator so names containing it can confuse the reader
    -   ***avoid*** names like
        `accident_wating_to_happen_`
-   use camel case or all lower case for multiple word identifiers
    -   `longFunctionName` or `longfunctionname`
-   use namespaces judiciously (see [function libraries](#function-libraries))
-   don't use `.` in names, as this looks like a namespace but its
    validity is actually a parser bug, future versions of KDB+ may not
    support variables with `.` 's in.
    -   **Do** `.myspace.myvar`
    -   ***Don't*** `myspace.myvar`

### Rules

-   Global constants (read-only) are descriptive nouns in all capitals
    -   `PORT`
-   Global variables (read/write - *avoid these if at
    all possible*) are descriptive nouns starting with an
    initial capital
    -   `Global`
-   Global functions are descriptive lower or camel case verbs
    -   `updatetrade` or `updateTrade`
-   Local functions are short lower case verbs
    -   `upd`
-   Local variables are short lower case nouns. Reserve `x`,`y`,`z` for
    positional parameters. `q` often uses the following conventions:
    -   `d` dictionary/date
    -   `v` vector
    -   `t` table
    -   `f` file/function
    -   `x`,`y`,`z` implicit function parameters
    -   `n` count
    -   `i` fabricated on demand during a query
    -   `h` handle
    -   `l` never use letter `l`, looks like number `1` in some fonts
        (*looks identical on this wiki*)
    -   `s` symbol

### Size does Matter

-   names that are too short are difficult to associate and search
-   names that are too long are time consuming to type/read and are
    prone to errors
-   names that are difficult to pronounce will be transcribed
    incorrectly
-   use criterion: *can the guy on the other end of the telephone type
    what i'm saying easily?*

### Reserve x, y, z

-   Use `x`,`y`,`z` to refer only to the first, second and third functional
    arguments
-   If you use other names for parameters ***do not*** use `x`,`y`,`z` as local variables

Indentation
-----------

-   Consistently indent two spaces in functions or control structures.
-   Use indentation to delineate nested control structures if you must
    have them.
-   Align:
    -   list items
    -   dictionary domain/range
    -   case statements
    -   table columns
    -   other obvious candidates in multi-line parallel constructs

```
trade:([]
  time:`time$();
  sym:`g#`symbol$();
  msg:`symbol$();   / original IDN message type
  tp:`float$();     / last trade price or value
  ts:`int$();       / trade volume
  tts:`long$();     / today's total trading volume
  smi:`symbol$();   / sub-market indicator
  te:`symbol$();    / trade exchange id
  tc:`symbol$();    / price type/condition
  tte:`symbol$();   / trade through exempt
  sq:`int$()        / sequence number
  );
```

-   *Gotcha*: ensure
    that a closing brace for a function split over several lines
    is indented.
    -   to avoid this keep the closing brace with the last line of
        the function.

```
// Generate n (int) random trades for symbols in s (symbol list), starting at st (time).
// Return the table.
genTrades:{[n;s;st]
  dur:8*60*60*1000; / 8 hours
  / generate and sort data
  `sym`time xasc ([] time:st+n?dur; sym:n?s; tp:25+n?50f; ts:100+100*n?100; oid:(n;10)#(10*n)?.Q.an)
} / this breaks code
```

instead write the function:

```
// Generate n (int) random trades for symbols in s (symbol list), starting at st (time).
// Return the table.
genTrades:{[n;s;st]
  dur:8*60*60*1000; / 8 hours
  / generate and sort data
  `sym`time xasc ([] time:st+n?dur; sym:n?s; tp:25+n?50f; ts:100+100*n?100; oid:(n;10)#(10*n)?.Q.an)}
```

Comments
--------

-   Every line of q code should be commented. This might sound like
    overkill but remember that this is primarily for others, not
    for you. Reading other people's code is much easier when succinct,
    relevant comments are provided. Other languages don't require per
    line comments but a single line of q can do a lot...
-   If you write short lines place the comments at the end of the line
    and align them

```
d:k!key each` sv'`,'k:(key`) except `q`Q`h`help / dictionary mapping all non system namespaces to their contents
```

-   If you have longer lines place the comment on the
    line before(logically) the code
-   Use function header comments:
    -   especially for non-trivial functions
    -   describe purpose of function
    -   describe expected values and forms of arguments
    -   describe any return value(s)
-   Use extra comment lines to explain
    -   meaning or purpose of local variables
    -   any side effects (i.e. non-local references)
    -   the working of a control structure and its condition(s)
-   Block comments:
    -   **do use** `//` to
        start each line
    -   ***avoid*** the `\`,
        `/` block comment pair
    -   it is easy to leave a dangling `\` on a line which will ignore
        all code

Compare this:

```
// Adds a new column to existing table.
// Arguments:
// dbdir : Path to database (as path symbol)
// table : Table name to be modified (as symbol) 
// colname : Column name to be added (as symbol) 
// defaultvalue: Default value for the new column 
// Example:
// Adding a new column named noo to trade table with default value of 0h
// .ms.dba.addCol[`:.;`trade;`noo;0h]
.ms.dba.addCol:{[dbdir;table;colname;defaultvalue]
```

with this:
```
/
Adds a new column to existing table.
Arguments:
dbdir : Path to database (as path symbol)
table : Table name to be modified (as symbol) 
colname : Column name to be added (as symbol) 
defaultvalue: Default value for the new column 
Example:
Adding a new column named noo to trade table with default value of 0h
.ms.dba.addCol[`:.;`trade;`noo;0h]
\
.ms.dba.addCol:{[dbdir;table;colname;defaultvalue]
```

Declarations
------------

### Curly Braces and Functions

-   A function of one statement should be written on a single line
-   If reasonable, a function that returns an explicit result should
    have the result isolated with the closing brace

```
// splay table to partition
// splay table t (passed by name), into directory d (hsym), enum file e (sym),
// and partition p (simple type like date). Sort the table according to column f (sym).
// return the table.
splaytable:{[d;e;p;f;t]
  if[not all .Q.qm each r:flip .sys.en[d;e]`. t;'`unmappable];       / enumerate all symbol columns
  {[d;t;i;x] @[d;x;:;t[x]i]}[d:.Q.par[d;p;t];r;iasc r f] each key r; / sort data by f (sym) column
  @[;f;`p#]@[d;`.d;:;f,(r:key r) except f];                          / write table to disk and apply `p#
  t}   
```

-   Functions that return no meaningful result should end with an
    isolated brace

```
// log message to stderr: message header (x string) and an atom or list to log.
logmessage:{[x;y] y,:(); s:{$[10h=type x;x;string x]};
  -2 s[x],": ",ys[0],/,",/:1_ys:$[10h=type y;enlist y;s each y];
  } / no return result
```

-   *Gotcha*: beware an
    unintended `;` before a closing brace it will result in no return
    value

```
generatetable:{[n] ([]sym:n?`3; tp:25+n?50f; ts:100*1+n?10);} / returns nothing
```

### Function shape

-   *Ideally, a physical line of code contains exactly one statement and
    one statement encodes one thought* (S. Apter)
-   A function whose code looks tall and skinny may be breaking the
    problem into chunks that are too small
-   A function that is short and fat may be breaking the problem into
    chunks that are too big
-   A line should rarely exceed 50 characters including spaces

### Function length

-   A function over ten lines is suspect
-   A function over twenty five lines is certifiable

### Function Parameters

-   Q is limited to 8 function parameters
-   Try to limit your own functions to less
-   Encapsulate complex arguments in q data structures
    -   list
    -   dictionary
    -   table

### Function Arguments

-   Think carefully about what value and form of arguments you accept
-   Consider the behavior of your function for bad input
    -   functions that form public API benefit from type checking of
        input
-   If it receives unexpected argument values or types
    -   Signal is OK
    -   Returning null is OK
    -   Returning invalid results is not

### Assignments

-   Assignments within a line should be:
    -   few
    -   short
    -   used only in that line
-   Longer assignments or ones used on multiple lines should be:
    -   factored onto separate lines
-   Pick a few letters for temporary assignment and use them
    consistently
    -   ***don’t use*** `x`, `y` , `z`
-   Think of values instead variables
    -   Assigned once
    -   Read-only thereafter
    -   Exception: can reuse one local to avoid duplicate storage for
        very large items

### Anonymous Functions

-   Use sparingly
    -   no more than one per line
-   Keep them short



Statements
----------

### Parentheses

-   Do not use unnecessary parentheses
    -   The compiler doesn't need them
    -   They confuse experienced q coders

Compare this:

```
camelCase:{[s] s[0],/{(upper 1#x),1_x,()} each 1_s} / camel case a list of strings
```

with this: ***confusing parentheses***
```
camelCase:{[s] s[0],/{(upper (1#x)),(1_x),()} each (1_s)} / camel case a list of strings
```

-   In expressions, only use parentheses around a complex left operand
    `(...) op ...`

```
-1 "result: ",(string floor a*100),"%";
```

-   Learn to rearrange expression elements to avoid parentheses
    -   ***avoid***
        `(count t) > 0`
    -   **use instead**
        `0<count t`
-   For monadic functions, use stronger binding brackets to avoid
    parentheses
    -   ***avoid***
        `"a=",(string a),", b=",string b`
    -   **use instead**
        `"a=",string[a],", b=",string b`

***Avoid*** parentheses `()`
containing statements on multiple lines, as these will be executed
bottom to top, returning a list containing the result of each statement

```
//calculate netpay after income tax (if uk, then after national insurance contributions)
cntry:`uk
threshold:500
gross:1000
INCOMETAXRATE:0.2
(1-INCOMETAXRATE)*$[cntry~`uk;
 ((gross-threshold)-NI;
  NI: gross*NIRATE;
  NIRATE:0.11);
 gross]
```

**use brackets[] instead** for normal top to bottom behaviour,
returning the result of the last statement
```
//calculate netpay after income tax (if uk, then after national insurance contributions)
(1-INCOMETAXRATE)*$[cntry~`uk;
 [NIRATE:0.11;
  NI: gross*NIRATE;
  (gross-threshold)-NI];
 gross]
```

White Space
-----------

-   Make sure to use whitespace where required
    -   avoid it where prohibited

**just enough** whitespace:

```
fileExists:{[x] not()~key hsym`$x}
```

***unnecessary*** whitespace:

```
fileExists: {[x] not () ~ key hsym ` $ x}
```

-   Use a blank after `;` separators
    -   in functions and control statements

```
s:(),s; @[s; where 10=type each s; $[`;]] / convert strings to symbols 
```

-   Use non-required blanks
    -   only to separate symbolic operators from operands in complex
        expressions
-   ***Do not use blanks around every operator***


Programming Practices
---------------------

### Avoid Iffy and Loopy Code

-   Use conditionals sparingly and correctly
-   Seek a single expression that handles main and edge cases

Example: code below handles chars and strings

```
s:(),s; @[s; where 10=type each s; $[`;]] / convert strings to symbols
```
-   Learn all the adverbs and use them

```
1 ` sv "out: " ,/: string til 3; / print list of 3 ints
```

-   Use do/while only while waiting on input
-   Do not hide stinking loops in each

***don't do this:***

```
a:til 10; {$[x<5;0N;x]} each a
```

**instead do this:**

```
a: til 10; @[a; where a<5; :; 0N]
```

### Projections

-   retain semicolons in projections to make the intent clear

***don't do this:***
```
f[x] .' L; / what's the valence of f ?
```

**instead do this:**
```
f[x;;] .' L; / aha! f takes three params of which last two are elided
```

### Verbs vs Functions

-   Use the verb form when practical
-   Do not use dyadic form just to make your code more concise

### Conditionals

-   Use ternary `$[; ; ]` whenever a result is returned
    -   There should be an assignment to its left
    -   Avoid side effects
-   Use `if[  ; ... ]` when you want side effects
    -   For example, to set multiple variables
-   Use if for signal
-   Use extended `$[; ; ; ... ; ]` for "case"

### Globals

-   Minimize use and number of globals
-   Read-only global variables are safe
-   Keep mutable global data in root context
    -   Allows simple checkpoint via context save/load
-   Factor update of globals so that each is updated by a "setter"
    function
    -   Makes trapping changes easy

### Function Libraries

-   Be aware of the contexts you use to avoid clashes with other
    libraries
    -   `.ms` namespace is reserved for the firm's shared function
        libraries
    -   any single letter namespace, and specifically `.q` and `.Q`, are
        reserved by Kx
-   Use contexts to create libraries to separate from main context for
    session work
-   Use a different context to separate implementation from API
-   Implement each library in a script
-   Global variable references in functions are bound to the current
    context when the function is defined
-   Example of a function library:
    -   `.ms.log` is the API context
    -   `.ms.log.priv` is the private implementation context
    -   all functions are defined inside `.ms.log`
    -   implementation functions are defined explicitly as
        `.ms.log.priv.funcname`


```
\d .ms
// Implementation and globals
.ms.log.priv.LEVELS:`emergency`alert`critical`error`warning`notice`info`debug;
.ms.log.priv.h:0;
.ms.log.priv.logMsg:{[p;m] ... }
// Public API
.ms.log.init:{[x] ... }
.ms.log.setLogLevel:{[x] ... }
.ms.log.getLogLevel:{...}
```

### Indexing and Evaluation

-   Juxtaposition reduces notational density - use it where appropriate

Example:

```
sums[til[10]] / difficult to read
sums til 10   / clear and precise 
```

-   Verb `@` and `.` can make things simpler
    -   use them judiciously

Example:

```
// @ used for functional composition
flip (ts;(count value@) each ts:tables`) / list of table names and their sizes
```

-   Sometimes you just have to use function `@` and `.`
    -   avoid several complex arguments

Example:

```
@[`.;tables[];0#]; / clear all tables
```


### Readability

-   Avoid passing null symbol `` ` `` as an argument to a functions, use
    `[]` instead. This makes it more obvious to the reader that you are
    calling the function with no arguments.

***avoid***

```
tables`
```

**use instead**

```
tables[]
```

