.finos.dep.list:([moduleName:()]version:();projectRoot:();scriptPath:();libPath:();loaded:`boolean$();unloads:();isOverride:`boolean$());
.finos.dep.currentModule:();

.finos.dep.priv.regModule:{[moduleName;version;projectRoot;scriptPath;libPath;override]
    if[not 10h=type moduleName; '"moduleName must be a string"];
    if[not 10h=type version; '"version must be a string"];
    if[not 10h=type projectRoot; '"projectRoot must be a string"];
    if[not 10h=type scriptPath; '"scriptPath must be a string"];
    if[not 10h=type libPath; '"libPath must be a string"];
    if[0=count moduleName; '"moduleName must not be empty"];
    if[0=count version; '"version must not be empty"];
    if[all 0=count each (projectRoot;scriptPath;libPath); '"at least one of projectRoot, scriptPath or libPath must be provided"];
    if[not .finos.dep.isAbsolute projectRoot; projectRoot:.finos.dep.resolvePathTo[system"cd";projectRoot]];
    if[not .finos.dep.isAbsolute scriptPath; scriptPath:.finos.dep.resolvePathTo[projectRoot;scriptPath]];
    if[not .finos.dep.isAbsolute libPath; libPath:.finos.dep.resolvePathTo[projectRoot;libPath]];
    if[first enlist[moduleName] in exec moduleName from .finos.dep.list;
        existing:.finos.dep.list moduleName;
        prevOverride:existing`isOverride;
        if[override and existing`loaded; '"cannot override already loaded module"];
        if[not override;
            if[not prevOverride;
                if[not version~existing`version; 'moduleName," version mismatch: ",version," (already registered: ",existing[`version],")"];
                if[not projectRoot~existing`projectRoot; 'moduleName," projectRoot mismatch: ",projectRoot," (already registered: ",existing[`projectRoot],")"];
                if[not scriptPath~existing`scriptPath; 'moduleName," scriptPath mismatch: ",scriptPath," (already registered: ",existing[`scriptPath],")"];
                if[not libPath~existing`libPath; 'moduleName," libPath mismatch: ",libPath," (already registered: ",existing[`libPath],")"];
            ];
            :(::);
        ];
    ];
    `.finos.dep.list upsert `moduleName`version`projectRoot`scriptPath`libPath`isOverride!(moduleName;version;projectRoot;scriptPath;libPath;override);
    };

.finos.dep.regModule:{[moduleName;version;projectRoot;scriptPath;libPath]
    .finos.dep.priv.regModule[moduleName;version;projectRoot;scriptPath;libPath;0b]};

.finos.dep.regOverride:{[moduleName;version;projectRoot;scriptPath;libPath]
    .finos.dep.priv.regModule[moduleName;version;projectRoot;scriptPath;libPath;1b]};

//maybe use common override method across all projects?
.finos.dep.try:{.finos.util.trp[x;y;{[z;e;t].finos.dep.errorlogfn"Error: ",e," Backtrace:\n",.Q.sbt t; z[e]}[z]]};
if[0<count getenv`FINOS_DEPENDS_DEBUG; .finos.dep.try:{[x;y;z]x . y}];

.finos.dep.priv.moduleStack:();

.finos.dep.loadModule:{[moduleName]
    if[first enlist[moduleName] in .finos.dep.priv.moduleStack;
        '"circular module load: "," -> " sv .finos.dep.priv.moduleStack,enlist moduleName;
    ];
    prevModule:.finos.dep.currentModule;
    .finos.dep.currentModule:moduleName;
    .finos.dep.priv.moduleStack,:enlist moduleName;
    res:.finos.dep.try[(1b;)@.finos.dep.priv.loadModule@;enlist moduleName;(0b;)];
    .finos.dep.currentModule:prevModule;
    .finos.dep.priv.moduleStack:-1_.finos.dep.priv.moduleStack;
    if[not first res; 'last res];
    };

.finos.dep.isLoaded:{[moduleName].finos.dep.list[moduleName;`loaded]};

//can be overwritten by user
.finos.dep.preLoadModuleCallback:{[moduleName]};
.finos.dep.postLoadModuleCallback:{[moduleName]};

.finos.dep.priv.loadModule:{[moduleName]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    if[.finos.dep.list[moduleName;`loaded]; :(::)];
    .finos.dep.preLoadModuleCallback[moduleName];
    scriptPath:.finos.dep.list[moduleName;`scriptPath];
    if[`module.q in key `$":",scriptPath;
        .finos.dep.include .finos.dep.joinPath(scriptPath;"module.q");
    ];
    .finos.dep.postLoadModuleCallback[moduleName];
    .finos.dep.list[moduleName;`loaded]:1b;
    };

.finos.dep.scriptPathIn:{[moduleName;script]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    path:.finos.dep.joinPath(.finos.dep.list[moduleName;`scriptPath];script);
    if[not {x~key x}`$":",path; '"script not found: ",path];
    path};

.finos.dep.scriptPath:{[script]
    if[()~.finos.dep.currentModule; '".finos.dep.scriptPath must be used in module.q"];
    .finos.dep.scriptPathIn[.finos.dep.currentModule 0;script]};

.finos.dep.loadScriptIn:{[moduleName;script]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    .finos.dep.include .finos.dep.scriptPathIn[moduleName;script];
    };

.finos.dep.loadScript:{[script]
    if[()~.finos.dep.currentModule; '".finos.dep.loadScript must be used in module.q"];
    .finos.dep.loadScriptIn[.finos.dep.currentModule 0;script]};

.finos.dep.execScriptIn:{[moduleName;script]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    system"l ",.finos.dep.scriptPathIn[moduleName;script];
    };

.finos.dep.execScript:{[script]
    if[()~.finos.dep.currentModule; '".finos.dep.loadScript must be used in module.q"];
    .finos.dep.execScriptIn[.finos.dep.currentModule 0;script]};

.finos.dep.libPathIn:{[moduleName;lib]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    path:.finos.dep.joinPath(.finos.dep.list[moduleName;`libPath];lib);
    pathFull:path,$[.z.o like "w*";".dll";".so"];
    if[not {x~key x}`$":",pathFull; '"library not found: ",pathFull];
    path};

.finos.dep.libPath:{[lib]
    if[()~.finos.dep.currentModule; '".finos.dep.libPath must be used in module.q"];
    .finos.dep.libPathIn[.finos.dep.currentModule 0;lib]};

.finos.dep.loadFuncIn:{[moduleName;lib;funcName;arity]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    libPath:`$":",.finos.dep.libPathIn[moduleName;lib];
    libPath 2:(funcName;arity)};

.finos.dep.loadFunc:{[lib;funcName;arity]
    if[()~.finos.dep.currentModule; '".finos.dep.loadFunc must be used in module.q"];
    .finos.dep.loadFuncIn[.finos.dep.currentModule 0;lib;funcName;arity]};

.finos.dep.loadDependencies:{[deps]
    if[-11h=type deps; deps:"\n"sv read0 deps];
    depsk:.j.k deps;
    if[not `dependencies in key depsk; '"no 'dependencies' element found"];
    .finos.dep.loadFromRecord each depsk`dependencies;
    };

if[()~key `.finos.dep.resolvers; .finos.dep.resolvers:(`$())!()];

.finos.dep.resolvers[`]:{`projectRoot`scriptPath`libPath#x};

.finos.dep.loadFromRecord:{[rec]
    resolver:$[`resolver in key rec; rec`resolver; `];
    if[not resolver in key .finos.dep.resolvers; '"unregistered resolver: ",.Q.s1 resolver];
    params:.finos.dep.resolvers[resolver][rec];
    override:0b;
    if[`override in key rec; if[rec`override; override:1b]];
    .finos.dep.priv.regModule[rec`name;rec`version;params`projectRoot;params`scriptPath;params`libPath;override];
    if[override; :(::)];
    if[`lazy in key rec;if[rec`lazy;
        if[`scripts in key rec; '"lazy modules cannot have scripts specified"];
        :(::);
    ]];
    .finos.dep.loadModule rec`name;
    if[`scripts in key rec; .ms.depends.loadScript[rec`name] each rec`scripts];
    };

.finos.dep.registerUnload:{[name;unload]
    if[not name in exec moduleName from .finos.dep.list; '"module not registered: ",name];
    .finos.dep.list[name;`unloads]:.finos.dep.list[name;`unloads],unload;
    };

.finos.dep.unloadErrorHandler:{[name;err]
    -2"error while unloading module ",name,": ",err;
    };

.finos.dep.priv.unload:{[name]
    {[name;handler]@[handler;::;.finos.dep.unloadErrorHandler[name]]}[name] each .finos.dep.list[name;`unloads];
    };

.finos.dep.priv.unloadAll:{
    .finos.dep.priv.unload each exec moduleName from .finos.dep.list;
    };

.z.exit:{[handler;x]
    .finos.dep.priv.unloadAll[];
    handler[x]}$[()~key `.z.exit; (::); .z.exit];
