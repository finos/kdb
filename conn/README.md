This is a wrapper around the standard hopen/hclose methods. It provides a number of additional features:
* Backup addresses for each connection
* Connection retry if the connection is broken unexpectedly
* Exponential backoff for connection retry
* Connect/disconnect callbacks per connection
* Customizable address resolution
* Registration of clients for better administration
* Modular connection callbacks (e.g. `.z.po`)

*Note:* The library overwrites `.z.po`, `.z.pc`, `.z.wo` and `.z.wc`. These should not be overridden in order to allow the library to function correctly.

Client side API
===============
* `.finos.conn.open[name;address;options]`  
   Opens a remote connection. It does NOT return a handle. Instead it associates the given name with the given address. Later the name can be used to send data through the connection. For non-lazy connections, it will then schedule a timer that opens the connection. If the connection fails, it is retried with exponential backoff. The same retry logic is also triggered whenever the connection is closed.
   The address may be a string, symbol, or a list of either. When a list is used, the addresses are tried in the specified order until connection succeeds (this is useful for failover).
   Options is a dictionary that may have the following elements:
   * `ccb`: connect callback, called with the connection name. Called after filling `.finos.conn.list[]` with the details of the new connection.
   * `dcb`: disconnect callback, called with the connection name. Called before changing the connection entry in `.finos.conn.list[]` (setting the fd value to null).
   * `rcb`: registration callback, called with the connection name and should return a dictionary with additional items for client registration (see below). Called after filling `.finos.conn.list[]` with the details of the new connection.
   * `ecb`: error-handler callback, called when connection to an address failed.
   * `timeout`: number of milliseconds to wait during the connection attempt.
   * `lazy`: boolean, defaults to false. When a connection is lazy, it is not opened via the timer, instead when using `.finos.conn.syncSend` or `.finos.conn.asyncSend` to send data through the connection when it is not open, an attempt is made to open it. If the connection attempt fails, the failed addresses (not the connection) are put on a blacklist for a specified time during which any attempt to open a lazy connection to that address will fail fast. (The reason for blacklisting the address rather than the name is that in some extreme circumstances a host may not reject the connection but also not respond within the timeout, which causes all clients to be blocked for the timeout amount. Blacklisting the address helps when there are multiple connections to the same host, such that not every connection in turn must wait out the timeout period, which could cause the earliest connections to fail to come off the blacklist, thus resulting in almost constant blockage).

* `.finos.conn.close[name]`: unregisters a connection, closing it and cancelling the reconnect timer as necessary.
* `.finos.conn.list[]`: returns a list of the registered connections. Some columns are well defined while retaining the freedom to add new columns in the future.
* `.finos.conn.syncSend[name;msg]`: send the specified sync message through the connection.
* `.finos.conn.asyncSend[name;msg]`: send the specified async message through the connection.
* `.finos.conn.asyncFlush[name]`: sends an async flush (::) to the connection (blocking until all previous messages are handed over to the OS TCP stack).
* `.finos.conn.syncFlush[name]`: sends a sync "" to the connection (blocking until the peer processes all previous messages, synchronizing with the peer).
* `.finos.conn.lazyToNormal[name]`: switch a lazy connection to non-lazy. The connection is scheduled for opening if not open already.
* `.finos.conn.normalToLazy[name]`: switch a non-lazy connection to lazy. The connection is NOT closed if it is open.

Overridable globals:
* `.finos.conn.defaultOpenConnTimeout`: defaults to 300000. The timeout applied to connections where the `timeout` parameter option is not provided.
* `.finos.conn.resolveAddress`: defaults to `enlist` and can be overridden to provide custom address resolution. Example use cases: a symbolic address could be resolved via ZooKeeper, a token could be attached to the connection string before passing it to `hopen`. The function must return a list of valid connection strings that can be passed to `hopen`.
* `.finos.conn.errorTrapAt`: defaults to @[;;] and called as the safe-evaluation operator for `hopen`, the connection and the disconnection callback. It can be changed to allow for more detailed debugging, such as printing a stack trace or sending an alarm via a user-provided alarming system.
* `.finos.conn.ccbErrorHandler[connName;err]`: error handler for the connect callback, called with the connection name and the error message.
* `.finos.conn.dcbErrorHandler[connName;err]`: error handler for the disconnect callback, called with the connection name and the error message.
* `.finos.conn.rcbErrorHandler[connName;err]`: error handler for the registration callback, called with the connection name and the error message.

Server side API
===============

* `.finos.conn.clientList[]`: returns a list of client connections. This includes the registration information provided by the client. Unregistered clients are still returned but with nulls in the relevant fields.
* `.finos.conn.register[options]`: registers a client. Called by `.finos.conn.open` from the client side (more specifically the code that actually does the connection opening and calls `rcb` and `ccb` if successful) with some default parameters plus those returned by `rcb`.
The possible options are:
   * `app` (symbol): the name of the application.
   * `conn` (symbol): the connection name used by the client. (Note that the client might be a not-finos-enabled kdb+ client or a non-kdb+ client, but still polite enough to register. Still it could come up with a value that its owner would find useful to distinguish between connections inside the client, or just pass in a null symbol if there is nothing helpful to use this field for.)
   * `host` (symbol): the host of the client – while the server can find out a name for the host, it might not be the most readable version (think of DNS aliases).
   * `pid` (int): the process ID of the client. (If OS PID doesn’t make sense on the client side, any integer identifier the client thinks useful.)
These elements (except for `app`) are filled in by `.finos.conn.open`. The client may provide `name` plus other options.

* `.finos.conn.addClientRegisterCallback[funcName]`: adds a callback that is called as part of `.finos.conn.register`. The callback will receive a dictionary containing every field used during the registration, including extra ones provided by the client.
* `.finos.conn.addClientConnectCallback[funcName]`: adds a callback that is called whenever a client is connected (allows for "modular `.z.po`").
* `.finos.conn.addClientDisconnectCallback[funcName]`: adds a callback that is called whenever a client is disconnected (allows for "modular `.z.pc`").
* `.finos.conn.addClientWSConnectCallback[funcName]`: adds a callback that is called whenever a websocket client is connected (allows for "modular `.z.wo`").
* `.finos.conn.addClientWSDisconnectCallback[funcName]`: adds a callback that is called whenever a websocket client is disconnected (allows for "modular `.z.wc`").
