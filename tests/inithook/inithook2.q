\l timer/timer.q
\l inithook/inithook.q

//Synchronous inithook example.
//This can be useful for large projects where the initialization code can be split
//across multiple files but there is a dependency between each bit. Inithook makes it
//easier to split and move this code around different files while also maintaining
//the correct execution order.

//These 3 setup steps could be in separate files.
globalSetup1:{`..a set params[`a]};
.finos.init.add[`params;`globalSetup1;`globalSetup];

globalSetup2:{`..b set params[`b]};
.finos.init.add[`params;`globalSetup2;`globalSetup];

globalSetup3:{`..c set params[`c]};
.finos.init.add[`params;`globalSetup3;`globalSetup];

//This should be in the main file.
doProcess:{
    -1"Processing... a=",string[a]," b=",string[b]," c=",string[c];
    };
.finos.init.add[`globalSetup;`doProcess;()];

main:{
    .finos.init.setGlobal[`params;`a`b`c!1 2 3];
    };

main[];

