\l timer/timer.q
\l inithook/inithook.q

//Asynchronous inithook example.
//Suppose we want to connect to two different services and run some code when both connections succeed.
//In this case we can use two separate inithook symbols to indicate which connection is done and then
//have an inithook depending on both so that it only runs when both provide calls are done.

tpConnected:{
    -1"TP connected";
    .finos.init.provide`tpConnected;
    };

gwConnected:{
    -1"GW connected";
    .finos.init.provide`gwConnected;
    };

doProcess:{
    -1"Doing something with both tp and gw...";
    };
.finos.init.add[`tpConnected`gwConnected;`doProcess;()];

connectToTp:{
    //simulate connecting to an external service
    .finos.timer.addRelativeTimer[{tpConnected[]};00:00:00.1];
    };

connectToGw:{
    //simulate connecting to an external service
    .finos.timer.addRelativeTimer[{gwConnected[]};00:00:00.2];
    };

main:{
    connectToTp[];
    connectToGw[];
    };

main[];
