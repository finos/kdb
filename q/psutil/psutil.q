// only implemented for linux
if[not(first string .z.o)in"l";
  '`nyi;
  ]

.finos.dep.include"../util/util.q"

///
// Get memory information about a process, possibly including USS, PSS, and swap.
// @param x pid
// @return A dictionary of memory information about the process.
.finos.psutil.memory_full_info:{
  pagesize:"J"$first system"getconf PAGE_SIZE";
  attrs:`vms`rss`shared`text`lib`data`dirty;
  memory_info:pagesize*first flip attrs!("JJJJJJJ";" ")0:.finos.util.read0f .Q.dd[`:/proc;x,`statm];
  memory_info:`rss`vms xcols memory_info;

  smaps:.Q.dd[`:/proc]x,`smaps;
  has_smaps:not not type key smaps;
  memory_info_maps:$[has_smaps;
    [
      r:.finos.util.read0f smaps;
      r:{y where x y}[{$[2=count t:":"vs x;any(first t)like/:("Private_*";"Pss";"Swap");0b]}']r;
      r:1024*sum each"J"${y group x}."S:\n"0:` sv -3_'r;
      r:{?[x;();();`uss`pss`swap!((sum;enlist,{x where x like"Private_*"}key x);`Pss;`Swap)]}r;
      r];
    ()];

  memory_info,memory_info_maps}

///
// Get some memory statistic for a process as a fraction of total physical system memory.
// The statistic should be one of the symbol keys of the dictionary returned by memory_full_info.
// @param x statistic
// @param y pid
// @return A float of the memory statistic for the process divided by total physical system memory.
.finos.psutil.memory_fraction:{.finos.psutil.memory_full_info[y][x]%last system"w"}
