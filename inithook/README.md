# inithook
The inithook feature allows defining dependencies between initialization code. This becomes most beneficial in large projects where initialization code may be spread between multiple files.

Applications using the inithook API should not execute any code other than
* defining functions
* promoting functions into inithooks
* very basic definitions that don't need external input, such as global constants

Inithook relies on the timer library to schedule the execution of inithooks, therefore the first inithook will execute after the entire file finishes loading.

Inithooks form a dependency graph where the nodes are the services and the edges are the functions. When defining an inithook, the user must define the preconditions and postconditions (the endpoints of the edges leading into and out of the graph). An inithook is only executed when all its preconditions are met. A node is considered to be met when all the incoming edges have been executed. There are only two exceptions. The special `start symbol is met at the start, therefore using this as the precondition allows defining top-level inithooks that don't have any other requirements. Otherwise, if a node has inithooks going out of it but no inithooks coming in, it is considered an async node and it is considered to be met when the .finos.init.provide function is explicitly called. This function does nothing for a regular (sync) node.

# API
* .finos.init.add[requires;funName;provides]
Defines an inithook. Requires and provides must be symbols or symbol lists. funName is the name of the function to execute as a symbol.
* .finos.init.before[funName]
Allows an inithook to be explicitly scheduled before another. This should be called in the provides list of the inithook that should run first. This is only for cases when you can't directly change the code that you are depending on - if you can, you should instead change it to introduce a new symbol that you can use on the provides list.
* .finos.init.after[funName]
Allows an inithook to be explicitly scheduled after another. This should be called in the requires list of the inithook that should run last. This is only for cases when you can't directly change the code that you are depending on - if you can, you should instead change it to introduce a new symbol that you can use on the requires list.
* .finos.init.provide[service]
This causes all inithooks that require the given service to be executed, but only if no inithook provides this service. This could be used in timers or other callbacks to indicate the completion of an async operation.
* .finos.init.debug[]
Runs all inithooks immediately, and without the safe evaluation that would normally print an error message and exit if an inithook fails. This can be useful for debugging a failing inithook by placing this function call at the bottom of the main script. However it is not recommended to leave it in production code.
* .finos.init.showState[]
Displays the table of remaining inithooks.
* .finos.init.setGlobal[name;val]
A shorthand for setting a global variable to the specified value and then also doing .finos.init.provide on the name.
* .finos.init.setTimeout[timeout]
Sets the timeout value. This should be set before the first inithook starts. If not all inithooks are finished before the timeout expires, the application will exit with an error message displaying the final inithook state.
* .finos.init.saveDependencyToSvg[outputFile]
Saves the inithook dependency graph to a file. This should be done after all inithooks have been executed. "dot" (from Graphviz) must be on the PATH for this to work.
* .finos.init.getExecTimeByFunction[]
Returns a table of execution times for each inithook.
* .finos.init.customStart[]
This function can be overridden and it is called before any inithooks are run.
* .finos.init.customEnd[]
This function can be overridden and it is called after all inithooks are run.
* .finos.init.errorHandler[hook;e]
This function can be overridden and it is called when an inithook fails. The default behavior is to crash the program with an error message.
