// .finos.mline[] allows multiple multi-line functions to be
//  pasted into the console.

// Will read STDIN until it sees "done" on a line by itself.
// It will then evaluate everything and return you to the regular
//  command prompt.
//
// Useful for tactically loading utility functions or testing out
//  monkey patches.
//
// Note!  This simple version does not play nice with \d .
//

.finos.mline:{
  r:();
  
  while[not "done"~line:read0 0
  // Put semicolons at beginning of lines that
  //  are not continuations or starts of comments.
       ;r,:enlist$[line like"[ \t/]*";"";";"],line];
  
  value` sv r}
