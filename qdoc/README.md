Documenting your Q
==================

Introduction
------------

Q can be a quirky and exceedingly terse language. For this reason
thorough documentation is highly encouraged. Within the firm a solution
has been engineered that uses
[javadoc](http://java.sun.com/j2se/javadoc/writingdoccomments/) syntax
to document your Q functions. It uses the
[NaturalDocs](http://www.naturaldocs.org/) framework behind the scenes
to generate the documentation.

**Features**

-   Search
    -   At the bottom left of the page is a search box which will help
        you find q files and function names.
-   Stub generation
    -   Functions without any documentation will be listed with their
        argument names.
-   Inter-file linking
    -   Using the @see syntax links can be made between files.
-   Context detection
    -   The system will automatically see calls to \\d and will adjust
        function names intelligently based on this.
-   Separation of public and 'private' functions, following the
    convention in the [Q coding
    guidelines](https://github.com/finos-data-tech/kdb/blob/master/enterprise-best-practices/q-coding-guidelines.md).
    -   The documentation will split functions with .priv. somewhere in
        their name into a different section of the documentation.

**Compatibility**

Due to a reliance on `lex(1)`, you'll need to compile binaries for the platforms you want to support.

Requires NaturalDocs 1.x, which is not officially supported any longer.  (Has been tested with 1.4.)  

Still available here:
-   https://www.naturaldocs.org/download/


A single function
-----------------

    ///
    // Prints the message you provide to the screen.
    // This can be multiple lines in length.
    //@param x The message.
    //@return The message.
    printMessage:{[x]
       show x; x
     };


Syntax at a glance
------------------

-   The three slashes are the minimum that must be provided in order for
    this to be considered as documentation.
-   From this point on two slashes are required.
-   Supported tags are:
    -   [@param](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@param)
    -   [@return](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@return)
    -   [@author](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@author)
    -   [@version](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@version)
    -   [@since](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@since)
    -   [@deprecated](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@deprecated)
    -   [@see](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@see)
    -   [@throws](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#@exception)
    -   [@link](http://www.oracle.com/technetwork/java/javase/documentation/index-137868.html#{@link})
-   Formatting (bolds, underline, lists, section headers, etc.) is [also
    available](https://www.naturaldocs.org/reference/formatting/).

Adding a section or header
--------------------------

You may want to add a usage or general notes section to some
documentation you are writing. In order for it to show up as its own
section it you need to follow this syntax.

    ///////////////////////////
    // About: SECTIONTITLE
    // Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam vitae 
    // turpis vel libero convallis rhoncus. Donec vitae arcu. Curabitur non 
    // purus. Ut pharetra, odio in tincidunt blandit, mi lacus dapibus massa, 
    // sit amet ultricies tellus ante eu ante. Phasellus sem orci, imperdiet 
    // at, commodo in, aliquam at, tortor. Nunc quis dui.
    ///////////////////////////

If you wanted to provide a usage section with code in a monospaced font
you need to preface each line of code by a greater than symbol.

    ///////////////////////////
    // About: Usage
    // Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam vitae 
    // turpis vel libero convallis rhoncus. Donec vitae arcu. Curabitur non 
    // purus. Ut pharetra, odio in tincidunt blandit, mi lacus dapibus massa. 
    // > CODE CODE CODE CODE CODE CODE CODE
    // Sit amet ultricies tellus ante eu ante. Phasellus sem orci, imperdiet 
    // at, commodo in, aliquam at, tortor. Nunc quis dui.
    // > CODE CODE CODE CODE CODE CODE CODE
    ///////////////////////////

Pulling it all together in a larger example
-------------------------------------------

    ////////////////////////////////////////
    // About: Math
    //
    // This is a dummy file that shows how code could be
    // documented using Natural Docs. There are simple math functions
    // present here for illustrative purposes. This section, along with usage,
    // is completely optional.
    //
    ////////////////////////////////////////
    // About: Usage
    // Here are some basic usage examples
    // > math.multiply[2;5]
    // Multiply 2 and 5.
    // > math.divide[10;2]
    // Divide 10 by 2.
    ////////////////////////////////////////

    //Section: Public

    \d .math

    ///
    //Multiplies two integers. This is a link to the divide method: {@link math.divide}.
    //@param x The first integer.
    //@param y The second integer.
    //@return The two integers multiplied together.
    //@since 2.5.200902XX
    //@see math.divide
    //@throws `length This is a dummy reason.
    multiply:{[x;y]
       x*y}

    ///
    //Divides two integers. This is a link to <a href="http://www.google.com">google.com</a>.
    //@param x The first integer.
    //@param y  The second integer.
    //@return x divided by y.
    //@see math.multiply
    //@deprecated Here is a reason for this function to be deprecated.
    //@author wesbo
    .math.divide:{[x;y]
       x%y}



Usage
-----

First add `qdoc` to your path as well as `NaturalDocs`.

Then it's a case of passing in your source directory along with where
you want the output to go.

    Usage:
    qdoc [SOURCE DIRECTORY] [DESTINATION DIRECTORY]
     Where:
     [SOURCE FOLDER]: The directory structure containing .q files.
     [DESTINATION DIRECTORY]: The location you want the html output to go.

Caveats
-------

### Public/Private functions

You'll notice if you have public and private functions interspersed in
your files the documentation will not group them into respective
sections. You'll need to do this grouping manually (ie put all of your
public functions at the start or end of your file).



Qtabledoc
---------

Analogous tool for documenting Q table schemas.

Look in `qtabledoc_example/` directory for an example.


How To Build
------------
Scripts:

`01build.ksh`
- compile qdoclex(1) and install companion perl scripts

`02test.ksh`
- run examples of qdoc and qtabledoc
- You'll need to edit the script to point `NATURAL_DOCS_1_DIR` at
  the directory containing the `NaturalDocs` 1 script.

`03clean.ksh`
- delete example output, build/, and install/

