// General-purpose utility functions.

///
// read0, but compatible with non-seekable files (fifos, /proc, etc.).
// @param x file symbol
// @return A list of strings containing the contents of the file.
// @see read0
.finos.util.read0f:{r:{y,read0 x}[h:hopen`$":fifo://",1_string x]over();hclose h;r}

///
// read1, but compatible with non-seekable files (fifos, /proc, etc.).
// @param x file symbol
// @return A byte vector containing the contents of the file.
// @see read1
.finos.util.read1f:{r:{y,read1 x}[h:hopen`$":fifo://",1_string x]over();hclose h;r}
