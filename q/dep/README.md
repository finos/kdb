## q dependency management

The FINOS q dependency manager aims to be the standard for loading q modules.

A module is described using a name, version, project root, script path and library path. The script and library path can be absolute or relative to the project root.

### Low-level API
* ```.finos.dep.regModule[moduleName;version;projectRoot;scriptPath;libPath]``` registers a module. It fails if attempting to register an already registered module with different parametes.
* ```.finos.dep.regOverride[moduleName;version;projectRoot;scriptPath;libPath]``` registers an override for a module. Unlike ```regModule``` this can change the parameters, but only if the module is not loaded yet.
* ```.finos.dep.loadModule[moduleName]``` loads the previously registered module.

### High-level API
* ```.finos.dep.loadFromRecord[rec]``` registers and optionally loads a module. It accepts a dictionary with the following keys:
  * ```name``` (string, mandatory): the name of the module
  * ```version``` (string, mandatory): the version of the module
  * ```resolver``` (symbol): the name of the resolver to use, see below
  * ```override``` (boolean): whether this is an override or not
  * ```lazy``` (boolean): if true, only register the module, don't load it
  * ```scripts``` (list of string): a list of scripts to load from the module, only allowed if ```lazy``` is false

### Resolvers
Resolvers can be used to construct the projectRoot, scriptPath and libPath for a module. The default resolver (whose name is the null symbol) simply picks out the ```projectRoot```, ```scriptPath``` and ```libPath``` elements of the record, so when using this resolver, these are mandatory as well. To define custom resolvers, assign them in the dictionary ```.finos.dep.resolvers```. The resolver must be a function that takes a dictionary (the same one that is used as the parameter to ```.finos.dep.loadFromRecord```) and must return a dictionary with the keys ```projectRoot```, ```scriptPath``` and ```libPath```, with all three values being strings.

### module.q
If a file named ```module.q``` is found in the script path, it is loaded as part of loading the module.

### Project files
If a file named ```qproject.json``` is found in the project root, it is processed before the module is loaded. If a ```dependencies``` element is found in the file, every element of it is passed to ```.finos.dep.loadFromRecord``` in sequence.

### Module helper functions
* ```.finos.dep.scriptPath[script]``` returns the path to the specified script relative to the script path of the current module
* ```.finos.dep.scriptPathIn[moduleName;script]``` returns the path to the specified script relative to the script path of the specified module
* ```.finos.dep.loadScript[script]``` loads a script relative to the script path of the current module, if not already loaded
* ```.finos.dep.loadScriptIn[moduleName;script]``` loads script relative to the script path of the specified module, if not already loaded
* ```.finos.dep.execScript[script]``` loads a script relative to the script path of the current module, does not interact with loadScript(In) for the "already loaded" check
* ```.finos.dep.execScriptIn[moduleName;script]``` loads script relative to the script path of the specified module, does not interact with loadScript(In) for the "already loaded" check
* ```.finos.dep.libPath[lib]``` returns the path to the specified library relative to the library path of the current module
* ```.finos.dep.libPathIn[moduleName;lib]``` returns the path to the specified library relative to the library path of the specified module
* ```.finos.dep.loadFunc[lib;funcName;arity]``` loads a function from the specified library relative to the library path of the current module
* ```.finos.dep.loadFuncIn[moduleName;lib;funcName;arity]``` loads a function from the specified library relative to the library path of the specified module
* ```.finos.dep.registerUnload[name;unload]``` adds a function to be run on process exit (due to the effects of module loading being irreversible, there is currently no support for unloading modules on the fly)

### include
The include feature of FINOS Module Loader allows intra-project file dependency management. This is the underlying function used by all the script loading in the dep library, with the exception of ```.finos.dep.execScript(In)```.
The core of this feature is the ```.finos.dep.include``` function which takes a string as a parameter and loads the specified file. Relative paths are considered to be relative to either the startup script or the file being loaded by the innermost include call - in other words, if you only use include to load your files, you can assume that relative paths are relative to the current file.
The include function does deduplication - it won't load a file that has already been loaded.
Circular includes will cause an exception.
The most important points when using include with relative paths:
   * It should only be called either from the main script, or in a file that is also loaded by include.
   * It should not be called from functions that get called from different files, as this may produce confusing results.
   * It should not be called from files loaded by \l. This also applies to any custom wrappers you might have written.
The above doesn't apply when using absolute paths.
Other functions and variables exported as part of this feature:
   * ```.finos.dep.currentFile[]``` returns the path of the current file being loaded
   * ```.finos.dep.cutPath[path]``` splits a path (string) into (directory;file) much like ``` ` vs ``` but works across platforms
   * ```.finos.dep.joinPath[paths]``` joins a list of paths (strings) using the system-specific path separator
   * ```.finos.dep.simplifyPath[path]``` removes all empty and "." path elements and collapses "dir/.." elements if possible
   * ```.finos.dep.resolvePath[file]``` returns the path to the file which is relative to the current file being loaded, or an absolute path which is returned unchanged
   * ```.finos.dep.resolvePathTo[dir;file]``` returns the path to the file which is relative to the specified directory, or an absolute path which is returned unchanged
   * ```.finos.dep.includedFiles[]``` returns all files loaded by include with their full paths
   * ```.finos.dep.includeDeps``` contains dependency information (which file includes which other)
   * ```.finos.dep.depsToDot[]``` converts the dependencies to "digraph" format so you can call GraphViz on it
