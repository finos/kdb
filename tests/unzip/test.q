.finos.dep.loadScriptIn["finos/kdb";"unzip/unzip.q"]

.finos.log.debug"pid: ",string .z.i

`. upsert .Q.def[(enlist`src)!enlist`$()].Q.opt .z.x;

src:hsym each src

r:.finos.util.progress[hcount;{.finos.unzip.unzip x;.finos.util.free[]};src]

.finos.util.free[]

show r
