\l timer/timer.q

.test.firstRun:1b;
f:{
    -1"f: ",string .z.P;
    if[.test.firstRun;
        .test.firstRun:0b;
        -1"running something slow...";
        system"sleep 5";
    ];
    };

t:.finos.timer.addPeriodicTimer[{f[]};00:00:02];
.finos.timer.setCatchUpMode[t;`none];
