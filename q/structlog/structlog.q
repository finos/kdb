// Name to level mapping based on Python:
//  https://docs.python.org/2/library/logging.html
//  https://github.com/hynek/structlog/blob/master/src/structlog/stdlib.py

.finos.structlog.level.NOTSET:0
.finos.structlog.level.DEBUG:10
.finos.structlog.level.INFO:20
.finos.structlog.level.WARNING:30
.finos.structlog.level.ERROR:40
.finos.structlog.level.CRITICAL:50

.finos.structlog.LEVEL_NAMES:`notset`debug`info`warning`error`critical
.finos.structlog.LEVEL_VALUES:.finos.structlog.level[upper .finos.structlog.LEVEL_NAMES]

.finos.structlog.NAME_TO_LEVEL:.finos.structlog.LEVEL_NAMES!.finos.structlog.LEVEL_VALUES


.finos.structlog.log:{[config;level;event;argDict]
  /// Generic logging function.
  if[10h=type event;event:`$event];
  preDict:`level`event!(level;event);
  d:preDict,argDict;
  p:config`processors;
  // Apply pipeline functions to the dictionary.
  d{[d;f]f@d}/p}


//////////
/// Fundamental pipeline stages.
//////////

.finos.structlog.addLocalTimestamp:{[d]
  /// Pipeline stage that augments its input dictionary with local time.
  //  Other applications may want UTC instead.
  preDict:enlist[`timestamp]!enlist .z.P;
  preDict,d}


.finos.structlog.trivialRenderer:{
  /// Render dictionary using -3!x since that works for everything.
  -3!x}


.finos.structlog.keyValueRenderer:{[d]
  /// Render dictionary using k=v, ... ordering.
  ", " sv{[k;v]string[k],"=",(-3!v)}'[key d;value d]}


//////////
/// Higher level pipeline stage(s).
//////////

/// "level" column assumes we're using Python level numbers.
.finos.structlog.structlogTable:([]
  timestamp:`timestamp$();
  level:`long$();
  event:`$(); // symbol - to later facilitate log counting
  d:()        // dictionaries
 )

/// Minimum required keys for logging to structlogTable.
.finos.structlog.REQUIRED_KEYS:`timestamp`level`event


.finos.structlog.tableInserter:{[t;d]
  /// Insert dictionary into "structlogTable".
  remainDict:.finos.structlog.REQUIRED_KEYS _ d;
  t insert d[.finos.structlog.REQUIRED_KEYS],enlist remainDict;
  // Return original dict unmolested for next pipeline stage.
  d}

//////////
/// Default "processors" pipeline.
//////////

.finos.structlog.priv.defaultConfig:enlist[`processors]!
  enlist(
    .finos.structlog.addLocalTimestamp;
    .finos.structlog.tableInserter[`.finos.structlog.structlogTable;];
    .finos.structlog.keyValueRenderer)


.finos.structlog.configure:{[configDict]
  /// Store a new configDict and return the previous one.
  oldConfig:.finos.structlog.priv.defaultConfig;
  .finos.structlog.priv.defaultConfig::configDict;
  oldConfig}

.finos.structlog.getLogger:{[]
  /// Returns a logger "object" - dictionary of lambdas bound to a
  //  desired configuration and level numbers.
  config:.finos.structlog.priv.defaultConfig;
  .finos.structlog.LEVEL_NAMES!.finos.structlog.log[config;;;]@/:.finos.structlog.LEVEL_VALUES}


