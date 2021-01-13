.finos.conn.priv.connections:([name:`$()]
    lazy:`boolean$();   //lazy connection not established immediately, only when attempting to send on it
    lazyRetryTime:`time$(); //time until the connection is tried again after a failure on lazy connections
    fd:`int$();         //file descriptor
    addresses:();       //list of destination addresses
    timeout:`long$();   //timeout when opening the connection
    ccb:();             //connect callback
    dcb:();             //disconnect callback
    rcb:();             //registration callback
    ecb:();             //error callback
    timerId:`int$());   //reconnection timer
.finos.conn.priv.defaultConnRow:`fd`lazy`ccb`dcb`rcb`ecb`timerId!(0N;0b;(::);(::);(::);(::);0N);

///
// The default timeout for opening connections, if the `timeout option is not provided.
.finos.conn.defaultOpenConnTimeout:300000;  //5 minutes
.finos.conn.priv.initialBackoff:500;
.finos.conn.priv.maxBackoff:30000;
.finos.conn.defaultLazyRetryTime:00:10:00t;

///
// Logging function.
// To replace with finos logging utils?
.finos.conn.log:{-1 string[.z.P]," .finos.conn ",x};

///
// Error trapping function for opening connections and invoking callbacks.
// Can be overwritten by user.
.finos.conn.errorTrapAt:@[;;];

///
// Open a new connection to a KDB+ server.
// @param name Name (symbol) for this connection, must be unique
// @param addresses A list of strings or symbols containing the connection strings, each is tried in sequence until one succeeds
// @param options a dictionary of connection info (`lazy`timeout`ccb`dcb`rcb`ecb)
//          lazy: connection not opened immediately but when an attempt is made to send data
//          timeout: the connection timeout in milliseconds
//          ccb: connect callback
//          dcb: disconnect callback
//          rcb: registration callback. Set to 0b to disable registration when connecting to a server not using .finos.conn.
//          ecb: error callback
// @return none
.finos.conn.open:{[name;addresses;options]
    if[type[addresses] in -11 10h; addresses:enlist addresses];
    if[11h=type addresses; addresses:string addresses];
    //set defaults
    connection:.finos.conn.priv.defaultConnRow,options,`name`addresses!(name;addresses);
    if[not `timeout in key connection; connection[`timeout]:.finos.conn.defaultOpenConnTimeout];
    if[not `lazyRetryTime in key connection; connection[`lazyRetryTime]:.finos.conn.defaultLazyRetryTime];
    //Argument validation
    if[-11h<>type connection`name;
      '"Invalid name type"];
    //Check to see if this name is already in use
    if[connection[`name] in exec name from .finos.conn.priv.connections;
      '"Name already exists"];

    extraCols:(key[connection] except cols[.finos.conn.priv.connections]) except`fd`timerId;
    if[0<count extraCols;
        '"unknown options: ",","sv string extraCols;
    ];
    if[not -7h=type connection`timeout; connection[`timeout]:`int$`time$connection`timeout];
    if[not -19h=type connection`lazyRetryTime; connection[`lazyRetryTime]:`time$connection`lazyRetryTime];
    `.finos.conn.priv.connections upsert connection;

    if[not connection`lazy;
        .finos.conn.priv.retryConnection[connection`name;.finos.conn.priv.initialBackoff];
    ];
    };

///
// Removes the lazy attribute from a connection. Immediately schedules the connection if not already open.
// @param connName Connection name
// @return none
.finos.conn.lazyToNormal:{[connName]
    if[not connName in exec name from .finos.conn.priv.connections;
        '"Connection not valid: ",string connName];
    .finos.conn.priv.connections[connName;`lazy]:0b;
    //if not already connected and not already trying to connect, try to connect now
    if[null .finos.conn.priv.connections[connName;`fd];
        if[null .finos.conn.priv.connections[connName;`timerId];
            .finos.conn.priv.retryConnection[connection`name;.finos.conn.priv.initialBackoff];
        ];
    ];
    };

///
// Adds the lazy attribute from a connection. However the connection is not closed.
// @param connName Connection name
// @return none
.finos.conn.normalToLazy:{[connName]
    if[not connName in exec name from .finos.conn.priv.connections;
        '"Connection not valid: ",string connName];
    .finos.conn.priv.connections[connName;`lazy]:1b;
    //if a connection is set to lazy while retrying, stop the retry
    if[not null tid:.finos.conn.priv.connections[connName;`timerId];
        .finos.timer.removeTimer tid;
        .finos.conn.priv.connections[connName;`timerId]:0Ni;
    ];
    };

.finos.conn.priv.retryConnection:{[connName;timeout]
    .finos.conn.priv.connections[connName;`timerId]:0Ni;
    if[not connName in exec name from .finos.conn.priv.connections;
        '"Connection not valid: ",string connName];
    if[null .finos.conn.priv.attemptConnection connName;
        .finos.conn.log"Retrying connection ",string connName;
        .finos.conn.priv.scheduleRetry[connName;timeout]];
    };

.finos.conn.priv.defaultErrorCallback:{[connName;hostport;error]
    .finos.conn.log"failed to connect ",string[connName]," to ",hostport,": ",error;
    };

.finos.conn.priv.resolverErrorCallback:{[connName;hostport;error]
    .finos.conn.log"failed to resolve ",string[connName]," hostport ",hostport,": ",error;
    ()};    //must return a list of hostports to try

///
// Called when a connection callback throws an error.
// Can be overwritten by user.
// @param connName Connection name
// @param err Error message
// @return none
.finos.conn.ccbErrorHandler:{[connName;err]
    .finos.conn.log"Connect callback threw signal: \"",err,"\" for conn: ",string connName;
    };

///
// Called when a disconnection callback throws an error.
// Can be overwritten by user.
// @param connName Connection name
// @param err Error message
// @return none
.finos.conn.dcbErrorHandler:{[connName;err]
    .finos.conn.log"Disconnect callback threw signal: \"", err, "\" for conn: ", string connName;
    };

///
// Called when a registration callback throws an error.
// Can be overwritten by user.
// @param connName Connection name
// @param err Error message
// @return A dictionary to make up for the failed callback.
.finos.conn.rcbErrorHandler:{[connName;err]
    .finos.conn.log"Registration callback threw signal: \"", err, "\" for conn: ", string connName;
    ()!()}; 

///
// Resolve a connection string. This function can be overwritten by the user.
// @param hostport The connection string passed to .finos.conn.open. Always a string.
// @return A list of actual connection strings that can be passed to hopen.
.finos.conn.resolveAddress:enlist;

.finos.conn.priv.lazyConnCooldownList:([addr:()]; lastErrorTime:`timestamp$());

.finos.conn.priv.attemptConnection:{[connName]
    hostports:.finos.conn.priv.connections[connName;`addresses];
    i:0;
    n:count hostports;
    // Check to see if we are actually connected, this will happen
    // if we managed to connect to an earlier hostport in the list.
    conn:.finos.conn.priv.connections[connName];
    fd:conn`fd;
    ecb:conn`ecb;
    if[ecb~(::);ecb:.finos.conn.priv.defaultErrorCallback];
    while[null[fd] and i<n;
        hostport:hostports i;
        cont:1b;
        resolvedHostports:();
        if[any hostport~/:exec addr from .finos.conn.priv.lazyConnCooldownList;
            $[.z.P>rt:.finos.conn.priv.lazyConnCooldownList[hostport;`lastErrorTime]+conn`lazyRetryTime;
                delete from `.finos.conn.priv.lazyConnCooldownList where addr~\:hostport;
                [cont:0b;
                    .finos.conn.log"Address ",hostport," is not retried for ",string`time$rt-.z.P
                ]
            ];
        ];
        if[cont;
            resolvedHostports:@[.finos.conn.resolveAddress;hostport;.finos.conn.priv.resolverErrorCallback[connName;hostport;]];
        ];
        while[(null fd) and 0<count resolvedHostports;
            resolvedHostport:first resolvedHostports;
            resolvedHostports:1_resolvedHostports;
            if[not null fd:.finos.conn.errorTrapAt[hopen;(resolvedHostport;conn`timeout);'[{0Ni};]ecb[connName;hostport;]];
                resolvedHostports:();
                .finos.conn.log"Connection ",string[connName]," connected to ",hostport;
                .finos.conn.priv.connections[connName;`fd]:fd;
                //Invoke the connect cb inside protected evaluation
                .finos.conn.errorTrapAt[
                    {.finos.conn.priv.connections[x;`ccb][x]};
                    connName;
                    .finos.conn.ccbErrorHandler[connName;]];
                regcb:.finos.conn.priv.connections[connName;`rcb];
                if[not 0b~regcb;
                    reginfo:$[regcb~(::);()!();@[regcb;::;.finos.conn.rcbErrorHandler[connName;]]];
                    if[not 99h=type reginfo; .finos.conn.log"registration callback didn't return a dictionary for conn: ",string[connName]; reginfo:()!()];
                    reginfo:reginfo,enlist[`connStr]!enlist .Q.s1 .finos.conn.list[][connName;`addresses];
                    .finos.conn.registerRemote[connName;reginfo];
                    @[.finos.conn.asyncFlush;connName;{}]; //fails with 'domain if handle=0
                ];
            ];
        ];
        if[(null fd) and .finos.conn.priv.connections[connName;`lazy] and not hostport in enlist[()],exec addr from .finos.conn.priv.lazyConnCooldownList;
            .finos.conn.log"Not retrying address ",hostport," for ",string[conn`lazyRetryTime];
            `.finos.conn.priv.lazyConnCooldownList upsert enlist`addr`lastErrorTime!(hostport;.z.P);
        ];
        i+:1;
    ];
    fd};

.finos.conn.priv.scheduleRetry:{[name;timeout]
    // Work out the next backoff timeout, if it's too high then go to the max
    newTimeout:$[.finos.conn.priv.maxBackoff<double:timeout*2;
        .finos.conn.priv.maxBackoff;
        double];
    .finos.conn.log"Scheduling retry for connection ",string[name]," in ",string newTimeout;
    .finos.conn.priv.connections[name;`timerId]:.finos.timer.addRelativeTimer[{[n;t;x].finos.conn.priv.retryConnection[n;t]}[name;newTimeout]; newTimeout];
    };

///
// Close an existing connection
// @param connName The name of the connection to close
// @return none
// @throws error if there is no connection with this name
.finos.conn.close:{[connName]
    if[-11h<>type connName;
        '"Invalid type for connName"];

    if[not connName in exec name from .finos.conn.priv.connections;
        '"No connection for this name!"];

    //If the connection is connected then close it
    if[not null h:.finos.conn.priv.connections[connName;`fd];
        hclose h];

    if[not null tid:.finos.conn.priv.connections[connName;`timerId];
        .finos.timer.removeTimer tid];

    //Remove it from the table
        delete from `.finos.conn.priv.connections where name=connName;
    };


///
// Returns the list of registered connections.
// @return A table with the columns matching the options to .finos.conn.open, plus fd for the connection handle.
.finos.conn.list:{.finos.conn.priv.connections};

.finos.conn.priv.lazyGetFd:{[connName]
    if[-11h<>type connName;
        '"Invalid name type"];
    if[null fd:.finos.conn.priv.connections[connName;`fd];
        if[.finos.conn.priv.connections[connName;`lazy];
            fd:.finos.conn.priv.attemptConnection[connName];
        ];
        if[null fd;
            '"Connection not valid: ",string connName
        ];
    ];
    fd};

///
// Synchronously execute on this connection
// @param name Connection name to use
// @param data Data to send
// @return The result of the calculation
// @throws error if there is no connection with this name
.finos.conn.syncSend:{[name;data]
    fd:.finos.conn.priv.lazyGetFd[name];
    fd data};

///
// Asnchronously execute on this connection
// @param name Connection name to use
// @param data Data to send
// @return none
// @throws error if there is no connection with this name
.finos.conn.asyncSend:{[name;data]
    fd:.finos.conn.priv.lazyGetFd[name];
    neg[fd] data};

///
// Blocks until all previous messages are handed over to the TCP stack
// @param name Connection name to use
// @return none
// @throws error if there is no connection with this name
.finos.conn.asyncFlush:{[name]
    .finos.conn.asyncSend[name;(::)]};

///
// Sends a sync chaser on the connection, blocking until all async messages have been processed by the peer.
// @param name Connection name to use
// @return none
// @throws error if there is no connection with this name
.finos.conn.syncFlush:{[name]
    .finos.conn.syncSend[name;""];
    };

.finos.conn.priv.lastClientConnID:0;
.finos.conn.priv.clientList:([fd:`int$()] protocol:`$(); app:`$(); conn:`$(); user:`$(); host:`$(); pid:`int$(); connID:`long$(); connStr:());

///
// Gets the list of connected clients.
// @return A table containing info such as fd, protocol, app, conn, user, host, pid, connID, connStr.
//         Some fields are filled in by the .finos.conn library, others are only filled in for registered clients.
.finos.conn.clientList:{.finos.conn.priv.clientList};

.finos.conn.priv.clientRegisterCallbacks:`$();
.finos.conn.priv.clientDisconnectCallbacks:`$();
.finos.conn.priv.clientConnectCallbacks:`$();
.finos.conn.priv.clientWSDisconnectCallbacks:`$();
.finos.conn.priv.clientWSConnectCallbacks:`$();

///
// Registers a client. This should be called from a client query such that .z.w is set. Automatically called on the server if a connection
// is opened by .finos.conn.open.
// @param items A dictionary that may contain the following items: app (symbol), conn (symbol), host (symbol), pid (int), connStr (string)
// @return none
.finos.conn.register:{[items]
    if[not 99h=type items; '"parameter to .finos.conn.register must be a dictionary"];
    if[0>system"p";if[0<>.z.w;:()]];   //don't overwrite globals in parallel process
    allItems:(.finos.conn.priv.clientList[.z.w],items),enlist[`fd]!enlist .z.w;
    if[0h=type allItems`connStr; allItems[`connStr]:""];
    `.finos.conn.priv.clientList upsert cols[.finos.conn.priv.clientList]#allItems;
    .finos.conn.priv.clientRegisterCallbacks @\: allItems;
    };

.finos.conn.priv.addGenericCallback:{[name;fn]
    if[not name in `clientRegisterCallbacks`clientDisconnectCallbacks`clientConnectCallbacks`clientWSDisconnectCallbacks`clientWSConnectCallbacks;
        '"invalid callback type";
    ];
    if[not -11h=type fn;'"function name must be a symbol"];
    value fn;    //to throw error if not defined
    varname:` sv `.finos.conn.priv,name;
    if[fn in value varname; '"duplicate callback - ",string[fn]];
    varname set varname,fn;
    };

///
// Add a callback that is called when a client registers. The callback receives a dictionary with the registration info.
// @param Symbol containing the name of the callback function.
// @return none
.finos.conn.addClientRegisterCallback:{.finos.conn.priv.addGenericCallback[`clientRegisterCallbacks;x]};

///
// Add a callback that is called when a client connects using KDB protocol. Can be used in place of chaining .z.po.
// @param Symbol containing the name of the callback function.
// @return none
.finos.conn.addClientConnectCallback:{.finos.conn.priv.addGenericCallback[`clientConnectCallbacks;x]};

///
// Add a callback that is called when a client disconnects using KDB protocol. Can be used in place of chaining .z.pc.
// @param Symbol containing the name of the callback function.
// @return none
.finos.conn.addClientDisconnectCallback:{.finos.conn.priv.addGenericCallback[`clientDisconnectCallbacks;x]};

///
// Add a callback that is called when a client connects using WebSocket protocol. Can be used in place of chaining .z.wo.
// @param Symbol containing the name of the callback function.
// @return none
.finos.conn.addClientWSConnectCallback:{.finos.conn.priv.addGenericCallback[`clientWSConnectCallbacks;x]};

///
// Add a callback that is called when a client diconnects using WebSocket protocol. Can be used in place of chaining .z.wc.
// @param Symbol containing the name of the callback function.
// @return none
.finos.conn.addClientWSDisconnectCallback:{.finos.conn.priv.addGenericCallback[`clientWSDisconnectCallbacks;x]};

///
// Register on a connection. This is called automatically as part of the .finos.conn.open connection procedure.
// @param conn Connection name
// @param items Dictionary of registration parameters
// @return none
.finos.conn.registerRemote:{[conn;items]
    items:(`conn`pid!(`;.z.i)),items;
    $[type[conn] in -6 -7h;
        [
            items[`conn]:`nonPersistent;
            sendFunc:neg[conn];
        ];
      -11h=type conn;
        [
            items[`conn]:conn;
            sendFunc:.finos.conn.asyncSend[conn];
        ];
      '"conn must be int or symbol"
    ];
    sendFunc({$[()~key`.finos.conn.register;::;.finos.conn.register[x]]};items);
    };

.finos.conn.priv.oldZpo:@[get;`.z.po;{}];
.finos.conn.priv.oldZpc:@[get;`.z.pc;{}];
.finos.conn.priv.oldZwo:@[get;`.z.wo;{}];
.finos.conn.priv.oldZwc:@[get;`.z.wc;{}];

///
// This callback registers basic info about the client and calls any user callbacks registered by .finos.conn.addClientConnectCallback.
.finos.conn.priv.Zpo:{[existingZpo;myfd]
    // Invoke the old .z.po as we're chaining these together
    `.finos.conn.priv.clientList upsert `fd`protocol`user`host`connID!(myfd;`kdb;.z.u;.Q.host[.z.a];.finos.conn.priv.lastClientConnID+:1);
    {[x;f]@[value f;x;{[f;h;e].finos.conn.log"Client connect callback ",string[f]," threw error ",e," for handle ",string h}[f;x]]}[myfd]each .finos.conn.priv.clientConnectCallbacks;
    existingZpo[myfd];
    };
.z.po:.finos.conn.priv.Zpo .finos.conn.priv.oldZpo;

///
// This callback is fired when a handle is disconnected. If this is one of
// our fd's, then schedule a reconnect attempt except for lazy connections.
//
// Note: We chain any existing .z.pc so that will be invoked _before_ this
// method. Additionally any user callbacks defined by .finos.conn.addClientDisconnectCallback are called.
//
// @param fd file descriptor that was disconnected
//
.finos.conn.priv.Zpc:{[existingZpc;myfd]
    // Invoke the old .z.pc as we're chaining these together
    existingZpc[myfd];

    connNames:exec name from .finos.conn.priv.connections where fd=myfd;
    {[connName]
        .finos.conn.log"Handle to ",string[connName]," disconnected.";
        //Invoke the disconnect cb inside protected evaluation
        .finos.conn.errorTrapAt[.finos.conn.priv.connections[connName;`dcb];connName;
            .finos.conn.dcbErrorHandler[connName;]];

        //Reset the fd for this connection to 0N so that it's retried
        .finos.conn.priv.connections[connName;`fd]:0N;

        if[not .finos.conn.priv.connections[connName;`lazy];
            //Start the connection retry
            .finos.conn.priv.scheduleRetry[connName;.finos.conn.priv.initialBackoff];
        ];
    } each connNames;
    {[x;f]@[value f;x;{[f;h;e].finos.conn.log"Client disconnect callback ",string[f]," threw error ",e," for handle ",string h}[f;x]]}[myfd]each .finos.conn.priv.clientDisconnectCallbacks;
    delete from `.finos.conn.priv.clientList where fd=myfd;
    };
.z.pc:.finos.conn.priv.Zpc .finos.conn.priv.oldZpc;

///
// This callback registers basic info about the client and calls any user callbacks registered by .finos.conn.addClientWSConnectCallback.
.finos.conn.priv.Zwo:{[existingZwo;myfd]
    // Invoke the old .z.wo as we're chaining these together
    `.finos.conn.priv.clientList upsert `fd`protocol`user`host`connID!(x;`ws;.z.u;.Q.host[.z.a];.finos.conn.priv.lastClientConnID+:1);
        {[x;f]@[value f;x;{[f;h;e].finos.conn.log"Client Websocket connect callback ",string[f]," threw error ",e," for handle ",string h}[f;x]]}[myfd]each .finos.conn.priv.clientWSConnectCallbacks;
    existingZwo[myfd];
    };
.z.wo:.finos.conn.priv.Zwo .finos.conn.priv.oldZwo;

///
// This callback calls any user callbacks registered by .finos.conn.addClientWSDisconnectCallback.
.finos.conn.priv.Zwc:{[existingZwc;myfd]
    // Invoke the old .z.wc as we're chaining these together
    existingZwc[myfd];
    {[x;f]@[value f;x;{[f;h;e].finos.conn.log"Client Websocket disconnect callback ",string[f]," threw error ",e," for handle ",string h}[f;x]]}[myfd]each .finos.conn.priv.clientWSDisconnectCallbacks;
    delete from `.finos.conn.priv.clientList where fd=myfd;
    };
.z.wc:.finos.conn.priv.Zwc .finos.conn.priv.oldZwc;
