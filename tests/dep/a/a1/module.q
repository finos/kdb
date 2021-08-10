if[not a2Loaded; '"a2 not loaded but is a dependency of this module"];
-1"this is a/a1";
a1Loaded:1b;
.finos.dep.include"a1s1.q";
.finos.dep.loadScript"a1s2.q";
