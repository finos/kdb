///
// Get name of current file that is being loaded via \l (4.0) or .finos.dep.include (3.6 or earlier)
// @return The file path as a string, or the start file (.z.f) if no \l / .finos.dep.include is running
.finos.dep.currentFile:$[.z.K>=4.0;{
    bt:(.Q.btx .Q.Ll`)[;1;3];
    l:first where bt like"\\l *";
    $[null l;
        string .z.f;    //this is needed to ensure any includes in the main script work properly
                        //unfortunately this also causes the function to misbehave if called outside of a file load
        //(::);
        3_bt l]};
    {.finos.dep.priv.currentFile}];

.finos.dep.pathSeparators:$[.z.o like "w*";"[\\/]";"/"];
.finos.dep.pathSeparator:$[.z.o like "w*";"\\";"/"];

///
// Cut a path into directory and file name
// @param path as a string.
// @return A list in the form (dir;file).
.finos.dep.cutPath:{[path]
    //Kx says that ` vs is too late to fix for Windows.
    path:"",path;
    match:path ss .finos.dep.pathSeparators;
    $[0<count match; [p:last match; (p#path;(p+1)_path)]; (enlist".";path)]};

///
// Cut a path into a list of directory names and file name
// @param path as a string.
// @return A list in the form (dir1;dir2;...;file). E.g. "aa/bb/cc" -> ("aa";"bb";"cc")
.finos.dep.splitPath:{[path]
    path:"",path;
    if[0=count path; :()];
    match:path ss .finos.dep.pathSeparators;
    enlist[first[match]#path],1_/:match cut path};

.finos.dep.joinPath:{[paths]
    paths:"",/:paths;
    .finos.dep.pathSeparator sv paths};

{
    if[.z.K<4.0;
        //check for existence, such that user can override with a more accurate path, e.g. without resolving symlinks
        if[()~key`.finos.dep.root; .finos.dep.root:.finos.dep.cutPath[first -3#value{}][0]];
        .finos.dep.priv.currentFile:.finos.dep.joinPath(.finos.dep.root;"finos_init.q");
    ];

    path:.finos.dep.cutPath[.finos.dep.currentFile[]][0];
    system"l ",.finos.dep.joinPath(path;"dep";"include.q");
    .finos.dep.include"dep/dep.q";
    .finos.dep.regModule["finos/kdb";"1.0";path;"";""];
    .finos.dep.list["finos/kdb";`loaded]:1b;

    if[.z.K<4.0;
        .finos.dep.priv.currentFile:string .z.f;
    ];
    }[];
