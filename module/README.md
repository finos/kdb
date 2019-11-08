The include feature of FINOS Module Loader allows intra-project file dependency management.
The core of this library is the .finos.dep.include function which takes a string as a parameter and loads the specified file. Relative paths are considered to be relative to either the startup script or the file being loaded by the innermost include call - in other words, if you only use include to load your files, you can assume that relative paths are relative to the current file.
The include function does deduplication - it won't load a file that has already been loaded.
Circular includes will cause an exception.
The most important points when using include with relative paths:
   * It should only be called either from the main script, or in a file that is also loaded by include.
   * It should not be called from functions that get called from different files, as this may produce confusing results.
   * It should not be called from files loaded by \l. This also applies to any custom wrappers you might have written.
The above doesn't apply when using absolute paths.
Other functions and variables exported as part of this feature:
   * .finos.dep.includedFiles[]: displays all files loaded by include with their full paths.
   * .finos.dep.includeDeps: contains dependency information (which file includes which other).
   * .finos.dep.depsToDot[]: converts the dependencies to "digraph" format so you can call GraphViz on it.
