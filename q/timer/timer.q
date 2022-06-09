//Want to protect the definition of these variables if script is reloaded in the same session.
if[not `idcount in key `.finos.timer.priv;
    .finos.timer.priv.idcount:0];
if[not `timers in key `.finos.timer.priv;
    .finos.timer.priv.timers:([id:`int$()] when:`timestamp$(); func:(); period:`timespan$();catchUpMode:`$())];

//these should be in util
.finos.util.trp:{[fun;params;errorHandler] -105!(fun;params;errorHandler)};
.finos.util.try2:{[fun;params;errorHandler] .finos.util.trp[fun;params;{[errorHandler;e;t] -2"Error: ",e," Backtrace:\n",.Q.sbt t; errorHandler[e]}[errorHandler]]};

.finos.timer.errorlogfn:-2;
.finos.timer.safeevalfn:.finos.util.try2;

.finos.timer.priv.FUNC_STR_MAX:1000
///
// Timer error handler. Can be replaced with user code.
// @param ctx A dictionary containing the timer details
// @param err Error
.finos.timer.timerErrorHandler:{[ctx;err]
    funcStr:ssr[.Q.s1 ctx`func;"\n";""];
    if[.finos.timer.priv.FUNC_STR_MAX<count funcStr;
        funcStr:((.finos.timer.priv.FUNC_STR_MAX-2)#funcStr),".."];
    .finos.timer.errorlogfn "timer got error ",err," from timer id=",string[ctx`id],", func=",funcStr;
    };

///
// Timer catch up mode. Determines what to do if a periodic timer takes longer to execute than its period.
// Possible values:
// `none: ignore the missed invocation - timer will run at the next occurrence
// `once: trigger missed invocations but multiple missed invocations are only triggered once
// `all: trigger all missed invocations - should only be used if the slowness is temporary and further invocations can indeed catch up
.finos.timer.defaultCatchUpMode:`once;
.finos.timer.priv.validCatchUpModes:`none`once`all;

.finos.timer.priv.runCallback:{[ctx]
    //Exit early if timer is not registered.
    //This can happen if two timers are scheduled to run at the same time, and the first one to run removes the second.
    if[not ctx[`id] in exec id from .finos.timer.priv.timers; :(::)];

    //Pass timer to the callback so it can use the ctx`id to remove itself if desired.
    //ctx`when can be used for the callback to know when it was supposed to be called so it can figure out if it's delayed.
    startTime:.z.P;
   .finos.timer.safeevalfn[ctx`func;enlist ctx;.finos.timer.timerErrorHandler[ctx;]];
    endTime:.z.P;

    //timer could have changed in the callback
    /ctx:exec from .finos.timer.priv.timers where id=ctx`id;
    .finos.timer.recordRunTime[ctx`id; endTime-startTime];

    if[null ctx`id;
        :(::)];
    if[null ctx`period;
        delete from `.finos.timer.priv.timers where id=ctx`id;
        :(::);
    ];
    now:.z.P;
    when:ctx`when;
    period:ctx[`period];
    when+:period;
    mode:ctx`catchUpMode;
    if[when<now;
        $[mode=`none;
            when+:period*ceiling (now-when)%period;
          mode=`all;
            ::;
          when+:period*(ceiling (now-when)%period)-1     //the "once" behavior which is also the default for invalid values
        ];
    ];
    .finos.timer.priv.timers[ctx`id;`when]:when;
    };

//can be overridden by user to record statistics about timers
.finos.timer.recordRunTime:{[tid;elapsed]};

.finos.timer.priv.ONEDAYMILLIS:`int$24:00:00.000
//reset \t value for next timer, or zero if there aren't any
.finos.timer.priv.setSystemT:{
    //only set timeout to zero if there are no more timers
    //Use ONEDAYMILLIS as max for timer to ensure int max not reached
    //.z.ts will wake up, have nothing to do and reset
    newVal:$[count when:asc exec when from .finos.timer.priv.timers;
        min(.finos.timer.priv.ONEDAYMILLIS;max(1;`int$`time$(first[when]|.z.P)-.z.P));
        0];
    system "t ",string newVal;
    };

//check callback symbol points to a function
.finos.timer.priv.validateCallback:{[callback]
    if[-11h=type callback;
         callback:get callback];
    if[not(type callback) in 100 104h;
     '"timer requires a function or projection"]}

.finos.timer.priv.wrapCallbackByName: {[f]
    .finos.timer.priv.validateCallback[f];
    $[-11h=type f;@[;]f;f]}

//replace callback function
.finos.timer.replaceCallback:{[tid;func]
    if[not type[tid] in -6 -7h; '"Expecting a integer id in .finos.timer.replaceCallback."];
    if[not tid in exec id from .finos.timer.priv.timers; '"invalid timer ID"];
    .finos.timer.priv.validateCallback[func];
    .finos.timer.priv.timers[tid;`func]:.finos.timer.priv.wrapCallbackByName func;
    };

//insert a new timer
.finos.timer.priv.addTimer:{[func;when;period]
    if[not null when; when:.finos.timer.priv.toTimestamp when];
    if[not null period; period:.finos.timer.priv.toTimespan period];
    .finos.timer.priv.validateCallback[func];
    id:.finos.timer.priv.idcount+1;
    if[not .finos.timer.defaultCatchUpMode in .finos.timer.priv.validCatchUpModes;
        '`$".finos.timer.defaultCatchUpMode has invalid value ",.Q.s1[.finos.timer.defaultCatchUpMode],", should be one of ",.Q.s1 .finos.timer.priv.validCatchUpModes;
    ];
    t:`id`when`func`period`catchUpMode!(id;when;func;period;.finos.timer.defaultCatchUpMode);
    `.finos.timer.priv.timers upsert t;
    .finos.timer.priv.idcount+:1;
    .finos.timer.priv.setSystemT[];
    id};

.finos.timer.priv.NANOSINMILLI:1000*1000j;
.finos.timer.priv.toTimespan:{
    $[-16h~t:type x; //timespan
        x;
      t in -6 -7h; //int, long = milliseconds
        `timespan$x*.finos.timer.priv.NANOSINMILLI;
      t in -17 -18 -19h; //minute, second, time
        `timespan$x;
      '`$"cannot convert to timespan: ",.Q.s1 x]};

.finos.timer.priv.toTimestamp:{
    $[-12h~t:type x; //timestamp
        x;
      -15h~t; //datetime
        `timestamp$x;
      t in -6 -7 -16 -17 -18 -19h; /int, long, timespan, minute, second, time
        (`timestamp$.z.D)+.finos.timer.priv.toTimespan x;
      '`$"cannot convert to timestamp: ",.Q.s1 x]};

///
// Add a periodic timer with the specified start time.
// @param func The function to run
// @param when The first invocation time (timestamp)
// @param period The timer period (time or timespan)
// @return Timer handle
.finos.timer.addPeriodicTimerWithStartTime:{[func;when;period]
    .finos.timer.priv.addTimer[func;when;period]};

///
// Add a timer that runs once at the specified time. If the time is in the past, the function is run immediately after returning from currently running functions.
// @param func The function to run
// @param when The invocation time (timestamp)
// @return Timer handle
.finos.timer.addAbsoluteTimer:{[func;when]
    .finos.timer.priv.addTimer[func;when;0Nn]};

///
// Add a timer that runs once at the specified time. If the time is in the past, the function is not run.
// @param func The function to run
// @param when The invocation time (timestamp)
// @return Timer handle
.finos.timer.addAbsoluteTimerFuture:{[func;when]
    $[.z.P<when:.finos.timer.priv.toTimestamp when;.finos.timer.priv.addTimer[func;when;0Nn];0N]};

///
// Add a periodic timer with the specified start time of day. If the time is in the future, it is run today, if it is in the past, it is run tomorrow.
// @param func The function to run
// @param startTime The first invocation time of day (time or timespan)
// @param period The timer period (time or timespan)
// @return Timer handle
.finos.timer.addTimeOfDayTimer:{[func;startTime;period]
    firstTrigger:$[.z.T < startTime; .z.D+startTime; (.z.D+1)+startTime];
    .finos.timer.addPeriodicTimerWithStartTime[func;firstTrigger;period]};

.finos.timer.priv.relativeToTimestamp:{.z.P+.finos.timer.priv.toTimespan x};

// Add a timer that runs once after a specified delay.
// @param func The function to run
// @param delay The time after which the timer runs (time or timespan)
// @return Timer handle
.finos.timer.addRelativeTimer:{[func;delay]
    .finos.timer.priv.addTimer[func;.finos.timer.priv.relativeToTimestamp delay;0Nn]};

// Add a periodic timer.
// @param func The function to run
// @param period The timer period (time or timespan)
// @return Timer handle
.finos.timer.addPeriodicTimer:{[func;period]
    .finos.timer.priv.addTimer[func;.finos.timer.priv.relativeToTimestamp period;period]};

// Remove a previously added timer.
// @param tid Timer handle returned by one of the addXXTimer functions.
.finos.timer.removeTimer:{[tid]
    if[not type[tid] in -6 -7h; '"Expecting an integer id"];
    delete from `.finos.timer.priv.timers where id=tid;
    };

// Change the frequency of a periodic timer or make a previously one-shot timer periodic.
// @param tid Timer handle returned by one of the addXXTimer functions.
// @param period The new timer period (time or timespan)
.finos.timer.adjustPeriodicFrequency:{[tid;newperiod]
    if[not type[tid] in -6 -7h; '"Expecting an integer id"];
    if[not tid in exec id from .finos.timer.priv.timers; '"invalid timer ID"];
    .finos.timer.priv.timers[tid;`period]:.finos.timer.priv.toTimespan newperiod;
    };

// Change the catch up mode of a periodic timer.
// @param tid Timer handle returned by one of the addXXTimer functions.
// @param mode One of the valid values for [[.finos.timer.defaultCatchUpMode]].
.finos.timer.setCatchUpMode:{[tid;mode]
    if[not type[tid] in -6 -7h; '"Expecting an integer id"];
    if[not type[mode]=-11h; '"Expecting a symbol mode"];
    if[not mode in .finos.timer.priv.validCatchUpModes; '`$"mode must be one of ",.Q.s1 .finos.timer.priv.validCatchUpModes];
    if[not tid in exec id from .finos.timer.priv.timers; '"invalid timer ID"];
    .finos.timer.priv.timers[tid;`catchUpMode]:mode;
    };

// Get the table of all timers.
.finos.timer.list:{.finos.timer.priv.timers};

{   //the "main" function
    restoreOld:0b;
    if[not ()~key `.z.ts;
        if[()~key `.finos.timer.priv.oldZts; //don't overwrite if this script is reloaded
            period:system"t";
            restoreOld:period>0;    //if period=0, timer is disabled so it shouldn't run
        ];
    ];
    if[restoreOld;
        .finos.timer.priv.oldZts:.z.ts;
    ];
    //invokes expired timers, reschedules periodic timers
    //and resets \t for next expiration
    .z.ts:{
        now:.z.P;
        toRun:`when xasc select from .finos.timer.priv.timers where when<=now;
        .finos.timer.priv.runCallback each 0!toRun;
        .finos.timer.priv.setSystemT[];};
    if[restoreOld;
        .finos.timer.addPeriodicTimer[.finos.timer.priv.oldZts;period];
    ];
    }[];
