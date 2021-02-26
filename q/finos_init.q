///
// Get name of current file that is being loaded via \l
// @return The file path as a string, or :: if no \l is currently running.
.finos.dep.currentFile:{
    bt:(.Q.btx .Q.Ll`)[;1;3];
    l:first where bt like"\\l *";
    $[null l;
        (::);
        3_bt l]};

.finos.dep.pathSeparators:$[.z.o like "w*";"\\";"/"];
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

.finos.dep.joinPath:{[paths]
    paths:"",/:paths;
    .finos.dep.pathSeparator sv paths};

system"l ",.finos.dep.joinPath(.finos.dep.cutPath[.finos.dep.currentFile[]][0];"module";"include.q");
.finos.dep.include"module/dep.q";
