.test.root:.finos.dep.cutPath[.finos.dep.currentFile[]]0;
.finos.dep.resolvers[`test]:{root:.test.root,"/",x[`name];`projectRoot`scriptPath`libPath!(root;"";"")};

.finos.dep.regModule["a/a1";"1.0";system["cd"],"/a/a1";"";""];
.finos.dep.loadModule"a/a1";
if[not a1Loaded; '"a1 not loaded"];
if[not a2Loaded; '"a2 not loaded"];
if[not a1s1Loaded; '"a1s1 not loaded"];
if[not a1s2Loaded; '"a1s2 not loaded"];
.finos.dep.loadScriptIn["a/a1";"a1s3.q"];
if[not a1s3Loaded; '"a1s3 not loaded"];
