//Probably this should NOT be replaced by a finos logging function,
//unless it supports contexts such that this can be its own context.
//The reason is that log might be initialized and redirected to a file,
//and log initialization itself might be done in an inithook.
//That would cause a break in where the log goes (stdout vs log file)
//which can make support tasks more difficult.
.finos.init.log:{-1 string[.z.P]," .finos.init ",x};

.finos.init.showState:{
    .finos.init.log "\nhooks:\n",.Q.s[.finos.init.priv.hooks],"services:",.Q.s .finos.init.priv.services;
    };

.finos.init.add2:{[requires;funName;provides;userParams]
    requires: (`$()),requires;
    provides: (`$()),provides;
    if[not -11h = type funName; '".finos.init.add2 expected type -11, found ",string[type funName],": ",.Q.s1[funName]];
    .finos.init.priv.addDependency[requires;funName;provides];
    if[0 < count exec fun from .finos.init.priv.hooks where fun = funName;
        .qcommon.priv.basicLogError ".finos.init.add: Tried to register a duplicate hook: ",.Q.s1 funName;
        '"duplicate_hook"];
    `.finos.init.priv.hooks upsert (funName;requires;provides;userParams);
    .finos.init.priv.finished::0b;
    .finos.init.priv.scheduleExecute[];
    };

.finos.init.priv.defaultUserParams:()!();

.finos.init.add:{[requires;funName;provides]
    .finos.init.add2[requires;funName;provides;.finos.init.priv.defaultUserParams]};

.finos.init.before:{[funName]
    //use on the provides list to force an inithook to run before another
    if[not funName in exec fun from .finos.init.priv.hooks; '".finos.init.before invalid inithook name: ",.Q.s1 funName];
    newCond:`$".finos.init.before:",string[funName];
    .finos.init.priv.hooks[funName;`requires]:distinct .finos.init.priv.hooks[funName;`requires],newCond;
    newCond};

.finos.init.after:{[funName]
    //use on the requires list to force an inithook to run after another
    if[not funName in exec fun from .finos.init.priv.hooks; '".finos.init.after: invalid inithook name: ",.Q.s1 funName];
    newCond:`$".finos.init.after:",string[funName];
    .finos.init.priv.hooks[funName;`provides]:distinct .finos.init.priv.hooks[funName;`provides],newCond;
    newCond};

.finos.init.provide:{[service]
    .finos.init.priv.services: distinct .finos.init.priv.services,service;
    .finos.init.priv.dependency.addProviderDependency[service];
    .finos.init.priv.scheduleExecute[];
    };

.finos.init.setGlobal:{[name;val]
    name set val;
    .finos.init.provide[name];
    };

.finos.init.getTimeout:{.finos.init.priv.initTimeout};
.finos.init.setTimeout:{
    if[not type[x] in -16 -17 -18 -19h ; '".finos.init.setTimeout expects time or timespan"];
    .finos.init.priv.initTimeout:x;
    };

.finos.init.setDefaultUserParams:{[newUserParams]
    if[not type[newUserParams]=99h; '".finos.init.setDefaultUserParams expects a dictionary"];
    .finos.init.priv.defaultUserParams:newUserParams;
    };

/*******************************************************************************
/* Private functions and variables
/*******************************************************************************

.finos.init.priv.hooks: ([fun: `$()] requires: (); provides: (); userParams:());
.finos.init.priv.stat:([fun:`$()] elapsedTime:`timespan$());
.finos.init.priv.services: `$();
.finos.init.priv.finished: 1b;
.finos.init.priv.debugRun: 0b;
.finos.init.priv.initTimeout: 00:01;

/ Use this very carefully!
.finos.init.priv.delete:{[hookNames]
    delete from `.finos.init.priv.hooks where fun in hookNames;
    };

//Can be overwritten by user. However there is only one of this, so if you end up fighting over it,
//you are using the inithook API wrong.
.finos.init.customStart:{};

.finos.init.priv.start:{
    .finos.init.customStart[];
    .finos.init.log "Initial hooks:\n",(.Q.s .finos.init.priv.hooks);
    };

//Can be overwritten by user. However there is only one of this, so if you end up fighting over it,
//you are using the inithook API wrong.
.finos.init.customEnd:{};

//these should be in util
.finos.util.trp:{[fun;params;errorHandler] -105!(fun;params;errorHandler)};
.finos.util.try2:{[fun;params;errorHandler] .finos.util.trp[fun;params;{[errorHandler;e;t] -2"Error: ",e," Backtrace:\n",.Q.sbt t; errorHandler[e]}[errorHandler]]};

//Can be overwritten by user.
.finos.init.errorHandler:{[hook;e]
    .finos.init.log:"Inithook ",.Q.s1[hook`fun]," died on error: ",e;
    exit 1;
    };

.finos.init.priv.executeOne:{
    if[.finos.init.priv.finished; :0b];
    if[0 = count .finos.init.priv.hooks;
        .finos.init.log "All hooks executed.";
        .finos.init.priv.finished:1b;
        .finos.init.customEnd[];
        :0b];

    hooks: select fun,provides,userParams from .finos.init.priv.hooks where
        not any each requires in\: () union/ provides,
        all each requires in\: .finos.init.priv.services;

    if[0 = count hooks;
        $[.finos.init.priv.debugRun;
            .finos.init.log "WARNING: Runnable hooks executed and can't progress! Check remaining hooks with .finos.init.state[]";
            .finos.timer.addRelativeTimer[{.finos.init.priv.checkFinished[]};.finos.init.priv.initTimeout]
        ];
        :0b
    ];

    hook: first hooks;
    hookName: hook[`fun];

    .finos.init.log "Executing ", string hookName;
    start:.z.P;
    res:$[.finos.init.priv.debugRun;
        (`success;hookName[]);
        .finos.util.try2[{(`success;value[x][])};enlist hookName;.finos.init.errorHandler[hook]]
    ];
    end:.z.P;
    .finos.init.priv.stat[hookName;`elapsedTime]:end-start;

    delete from `.finos.init.priv.hooks where fun = hookName;
    if[`success=first res;
        .finos.init.priv.services: distinct .finos.init.priv.services,hook[`provides];
    ];
    1b};

.finos.init.priv.timer:0Ni;

.finos.init.priv.execute:{
    while[.finos.init.priv.executeOne[]];
    .finos.init.priv.timer:0Ni;
    };

.finos.init.priv.scheduleExecute:{
    if[not null .finos.init.priv.timer; :(::)];
    .finos.init.priv.timer:.finos.timer.addRelativeTimer[{.finos.init.priv.execute[x]};0];
    };

.finos.init.debug:{
    .include.handleErrors:0b;
    .finos.util.try2:{[fun;params;errorHandler].[fun;params]};
    .finos.init.priv.debugRun::1b;
    .finos.init.priv.execute[];
    };

//Can be overwritten by user.
.finos.init.customTimeout:{};

.finos.init.priv.checkFinished:{
    .finos.init.customTimeout[];
    if[(not .finos.init.priv.finished) and (not .finos.init.priv.debugRun);
        notProvided:(distinct raze exec requires from .finos.init.priv.hooks)except .finos.init.priv.services,raze exec provides from .finos.init.priv.hooks;
        msg: "ERROR: Init hooks not finished within ", (string .finos.init.priv.initTimeout), "ms!\n",
            "Waiting: ",.Q.s1[exec fun from .finos.init.priv.hooks],$[0<count notProvided;" Services not provided: ",.Q.s1[notProvided];""];
        .finos.init.log msg;
        .finos.init.state[];
        .alarm.dev.critical[`inithooksNoProgress;`;msg];
        exit 1];
    };

//monitoring dependencies of the inithooks

.finos.init.priv.dependency.provideCount:(`$())!`int$();
.finos.init.priv.dependency.edges:([] from:`$(); to:`$());
.finos.init.priv.dependency.nodes:([name: `$()] label: `$(); nodeType: `$());

.finos.init.priv.dependency.escapeDot:{
    `$ ssr[; ".";"_"] string x};

.finos.init.priv.addDependency:{[requires;funName;provides]
    requiresEscaped:.finos.init.priv.dependency.escapeDot each requires;
    funNameEscaped:.finos.init.priv.dependency.escapeDot[funName];
    providesEscaped:.finos.init.priv.dependency.escapeDot each provides;

    .finos.init.priv.dependency.nodes[funNameEscaped]:(funName;`function);

    //preconditions
    `.finos.init.priv.dependency.edges insert flip flip(requiresEscaped;funNameEscaped);
    .finos.init.priv.dependency.nodes[providesEscaped]:flip flip(requires;`condition);

    //postconditions
    `.finos.init.priv.dependency.edges insert flip flip(providesEscaped;funNameEscaped);
    .finos.init.priv.dependency.nodes[providesEscaped]:flip flip(provides;`condition);
    };

.finos.init.priv.dependency.addProviderDependency:{[name]
    provider: `$"provide_",string[name];
    $[provider in key .finos.init.priv.dependency.provideCount;
        .finos.init.priv.dependency.provideCount[provider]:.finos.init.priv.dependency.provideCount[provider]+1;
        [
            .finos.init.priv.dependency.provideCount[provider]:1;
            .finos.init.priv.dependency.nodes[.finos.init.priv.dependency.escapeDot[name]]:(name;`condition);
            .finos.init.priv.dependency.nodes[provider]:(`;`provider);
            `.finos.init.priv.dependency.edges insert (provider; .finos.init.priv.dependency.escapeDot[name]);
        ]
    ];
    };

.finos.init.priv.dependency.convertToDotFormat:{[]
    cmd:"digraph G {\n";
    cmd,:raze { "  ",string[x`name]," [shape=ellipse, style=filled, color=palegreen, label=\"",string[x`label],"\"];\n"
        } each () xkey select from .finos.init.priv.dependency.nodes where nodeType=`function;
    cmd,:raze { "  ",string[x`name]," [shape=diamond, style = filled, color=salmon2, label=\"",string[x`label],"\"];\n"
        } each () xkey select from .finos.init.priv.dependency.nodes where nodeType=`condition;
    cmd,:raze { "  ",string[x`name]," [shape=septagon, label=\"",string[.finos.init.priv.dependency.provideCount[x`name]],"\"];\n"
        } each () xkey select from .finos.init.priv.dependency.nodes where nodeType=`provider;
    cmd,:raze { "  ",string[x`from]," -> ",string[x`to],";\n"
        } each .finos.init.priv.dependency.edges;
    cmd,:"}\n";
    cmd};

.finos.init.saveDependencyToSvg:{[outputFile]
    if[not 10h = type outputFile; '".finos.init.saveDependencyToSvg expects a string as argument - for example \"inithook_graph.svg\""];
    inputFile: first system"mktemp";
    inputFileH:hsym `$inputFile;
    inputFileH 0: enlist .finos.init.priv.dependency.convertToDotFormat[];
    //should be safesystem
    res:@[{(1b;system x)};"dot -Tsvg ",inputFile," -o '",ssr[outputFile;"'";"'\\''"];(0b;)@];
    hdel inputFileH;
    if[not first res; '"failed to run graphviz, check stderr"];
    };

.finos.init.getExecTimeByFunction:{
    `elapsedTime xasc .finos.init.priv.stat};

/*******************************************************************************
/* code that actually executes something
/*******************************************************************************

.finos.init.add[();`.finos.init.priv.start;`start];
