.finos.dep.list:([moduleName:()]version:();scriptPath:();libPath:());
.finos.dep.currentModule:();

.finos.dep.regModule:{[moduleName;version;scriptPath;libPath]
    if[moduleName in key .finos.dep.list;
        if[not version~.finos.dep.list[moduleName;`version];
            '"module conflict: ",moduleName," version ",version," (already registered: ",.finos.dep.list[moduleName;`version],")";
        ];
    ];
    `.finos.dep.list insert `moduleName`version`scriptPath`libPath!(moduleName;version;scriptPath;libPath);
    };

.finos.dep.override:{[moduleName;version;scriptPath;libPath]
    if[not moduleName in key .finos.dep.list;
        if[not version~.finos.dep.list[moduleName;`version];
            '"module not registered: ",moduleName;
        ];
    ];
    `.finos.dep.list insert `moduleName`version`scriptPath`libPath!(moduleName;version;scriptPath;libPath);
    };

//maybe use common override method across all projects?
.finos.dep.try:(.);

.finos.dep.loadModule:{[moduleName;version]
    prevModule:.finos.dep.currentModule;
    .finos.dep.currentModule:(moduleName;version);
    res:.finos.dep.try[(1b;)@.finos.dep.priv.loadModule@;(moduleName;version);(0b;)];
    .finos.dep.currentModule:prevModule;
    if[first res; 'last res];
    };

.finos.dep.priv.loadModule:{[moduleName;version]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    .finos.dep.include .finos.dep.list[moduleName;`scriptPath],"/module.q";
    };

.finos.dep.scriptPathIn:{[moduleName;script]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    path:.finos.dep.list[moduleName;`scriptPath],"/",script;
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
    };

.finos.dep.libPathIn:{[moduleName;lib]
    if[not moduleName in key .finos.dep.list; '"module not registered: ",moduleName];
    path:.finos.dep.list[moduleName;`libPath],"/",lib;
    pathFull:path,$[.z.o like "w*";".dll";".so"];
    if[not {x~key x}`$":",path; '"library not found: ",pathFull];
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
