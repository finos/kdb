.finos.dep.simplifyPath:{[path]
    path:ssr[path;"/";.finos.dep.pathSeparator];
    path:.finos.dep.pathSeparator vs "",path;    //ensure it's a string
    path:path where not(enlist ".")~/:path; //remove "." elements
    path:(1#path),(1_path) except enlist""; //remove blank elements (e.g. from dir//file)
    path:{                  //iteratively remove "dir/.." parts from path
        if[not ".." in x;:x];
        pos:(first where x~\:"..");
        pref:(pos-1)#\:x;
        suf:(pos+1)_\:x;
        :pref,suf;
    }/[path];
    path:.finos.dep.pathSeparator sv path;
    path};

//these should be in util
.finos.util.trp:{[fun;params;errorHandler] -105!(fun;params;errorHandler)};
.finos.util.try2:{[fun;params;errorHandler] .finos.util.trp[fun;params;{[errorHandler;e;t] -2"Error: ",e," Backtrace:\n",.Q.sbt t; errorHandler[e]}[errorHandler]]};

if[()~key `.finos.dep.logfn; .finos.dep.logfn:-1];
.finos.dep.errorlogfn:-2;
.finos.dep.safeevalfn:.finos.util.try2;

.finos.dep.isAbsolute:$[.z.o like "w*";
    {x like "?:*"};
    {x like "/*"}];

.finos.dep.startupDir:system"cd";
.finos.dep.loaded^:(enlist .finos.dep.simplifyPath$[.finos.dep.isAbsolute .z.f;string .z.f;(system "cd"),.finos.dep.pathSeparator,string .z.f])!enlist 1b;
.finos.dep.includeStack:1#key .finos.dep.loaded;
.finos.dep.includeDeps:([]depFrom:();depTo:());

.finos.dep.priv.callTree:([]callFrom:(); callTo:());  //like includeDeps but only actually called files are put here
.finos.dep.priv.stat:([file:()]elapsedTime:`timespan$());

.finos.dep.resolvePathTo:{[dir;file]
    .finos.dep.simplifyPath$[.finos.dep.isAbsolute file;file;.finos.dep.joinPath(dir;file)]};

.finos.dep.resolvePath:{[file]
    currFile:.finos.dep.currentFile[];
    path:$[(::)~currFile; system"cd"; .finos.dep.cutPath[currFile][0]];
    .finos.dep.resolvePathTo[path;file]};

//set to false to see where the loaded scripts break
//however this will corrupt the include stack, so don't use include again after an error
.finos.dep.handleErrors:1b;
if[0<count getenv`FINOS_DEPENDS_DEBUG; .finos.dep.handleErrors:0b];

.finos.dep.priv.errorHandler:{[path;x]
    .finos.dep.loaded[path]:0b;
    .finos.dep.includeStack:(count[.finos.dep.includeStack]-1)#.finos.dep.includeStack;
    .finos.dep.errorlogfn["Error while loading ",path,": ",x];
    'x};

///
// Include the specified file. Path is relative to the initial script (.z.f) or the current file if it's being included. Files won't be included more than once.
// This function should be used only outside of functions, and only in top-level scripts or in scripts included using this function.
// It should not be used from scripts loaded using \l or wrappers around it.
// @param force If true, load this file even if already loaded
// @param file File to include
.finos.dep.includeEx:{[force;file]
    if[0=count file; '"include: empty path"];
    path:.finos.dep.resolvePath file;
    $[()~kp:key hsym`$path;
        {'`$x}path," doesn't exist";
      11h=type kp;
        {'`$x}path," is a directory";
      ()
    ];
    `.finos.dep.includeDeps insert (`depFrom`depTo!(last .finos.dep.includeStack;path));
    if[path in .finos.dep.includeStack;
        .finos.dep.errorlogfn["Circular include:\n","\n-> "sv (.finos.dep.includeStack?path)_.finos.dep.includeStack,enlist path];
        '"Circular include in ",path;
    ];
    if[force or not .finos.dep.loaded[path];
        `.finos.dep.priv.callTree insert (`callFrom`callTo!(last .finos.dep.includeStack;path));
        .finos.dep.loaded[path]:1b;
        .finos.dep.logfn ((count[.finos.dep.includeStack]-1)#" "),"include: loading file ",path;
        .finos.dep.includeStack:.finos.dep.includeStack,enlist path;
        start:.z.P;
        $[.finos.dep.handleErrors;
            .finos.dep.safeevalfn[system;enlist"l ",path;.finos.dep.priv.errorHandler[path]];
            system"l ",path
        ];
        end:.z.P;
        .finos.dep.priv.stat[([]file:enlist path);`elapsedTime]:end-start;
        .finos.dep.includeStack:(count[.finos.dep.includeStack]-1)#.finos.dep.includeStack;
    ];
    };

.finos.dep.include:.finos.dep.includeEx[0b;];

.finos.dep.includeFromModule:{
    if[10h=type x; x:`$"/"vs x];
    s:.finos.dep.scriptPath[x];
    $[0<count s;.finos.dep.include s;'".finos.dep.scriptPath returned empty string for ",.Q.s1 x]};

.finos.dep.includedFiles:{asc where .finos.dep.loaded};

///
// Convert the include dependencies into dot format
.finos.dep.depsToDot:{
    "\n"sv((enlist"digraph G {"),(" ",/:" -> "sv/:(("\"",/:/:flip value flip last each/:.finos.dep.pathSeparator vs/:/:.finos.dep.includeDeps),\:\:"\"")),\:";"),enlist enlist"}"}

.finos.dep.getLoadTimeByFile:{enlist[first .finos.dep.includeStack] _ asc (exec file!elapsedTime from .finos.dep.priv.stat)-(exec sum .finos.dep.priv.stat[([]file:callTo);`elapsedTime] by callFrom from .finos.dep.priv.callTree)};
