.test.root:.finos.dep.cutPath[.finos.dep.currentFile[]]0;
.finos.dep.resolvers[`test]:{
    if[x[`name]~"a/a5"; '"sorry, wrong resolver"];
    root:.test.root,"/",x[`name];`projectRoot`scriptPath`libPath!(root;"";"")};
.finos.dep.resolvers[`test2]:{root:.test.root,"/test2/",x[`name];`projectRoot`scriptPath`libPath!(root;"";"")};

.finos.dep.regModule["a/a1";"1.0";system["cd"],"/a/a1";"";""];
.finos.dep.loadModule"a/a1";
if[not a1Loaded; '"a1 not loaded"];
if[not a2Loaded; '"a2 not loaded"];
if[not a1s1Loaded; '"a1s1 not loaded"];
if[not a1s2Loaded; '"a1s2 not loaded"];
.finos.dep.loadScriptIn["a/a1";"a1s3.q"];
if[not a1s3Loaded; '"a1s3 not loaded"];
.finos.dep.loadFromRecord`name`version`resolver!("a/a3";"0.0";`test);
if[not a3Loaded; '"a3 not loaded"];
.finos.dep.loadFromRecord`name`version`resolver!("a/a4";"0.0";"test");
if[not a4Loaded; '"a4 not loaded"];

a5Loaded:0b;
.finos.dep.loadFromRecord`name`version`resolver`override!("a/a5";"0.0";"test2";1b);
if[a5Loaded; '"a5 loaded when it shouldn't have"];
.finos.dep.loadFromRecord`name`version`resolver!("a/a5";"0.0";"test");
if[not a5Loaded; '"a5 not loaded"];
if[a5Loc<>2; '"a5 loaded from wrong location"];
