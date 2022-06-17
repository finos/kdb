Generic timer multiplexer

Allows callbacks to be invoked on independent schedules, periodically or only once, using relative or absolute expiration times. Scheduled callbacks can be cancelled if they have not expired yet. Uses .z.P for time calculations. Use local time for absolute timers.

The timer library sets the kdb timer callback, .z.ts, and also updates the timer frequency (\t) on every timer callback invocation. When using this library, you must not manually set .z.ts and should generally not manually change the timer frequency. All timers must be set and rescheduled with the functions in the API. The exception is you can pause the timer by setting the timer frequency to zero (\t 0) and restart it by setting it to 1 (\t 1).

Timer callbacks that throw error signals will be passed to an error handler that can be overridden by user.

Example:
```
q)tid:.finos.timer.addPeriodicTimer[{0N!"A",string .z.T;}; 1000]
q).finos.timer.addRelativeTimer[{0N!"C",string .z.T;}; 6000]
q).finos.timer.addAbsoluteTimer[{0N!"D",string .z.T;}; .z.T+7500]
q).finos.timer.removeTimer tid
```

API
===
`func` can be a function or a symbol.
`when` can be a temporal type indicating a point in time (timestamp is recommended). If there is no date component, it refers to today.
`period` is a temporal type indicating a period (timespan is recommended).
The _add_ functions return a timer ID that can then be used to manipulate the timer.

* `.finos.timer.addAbsoluteTimer[func;when]`: Run `func` at `when`.
* `.finos.timer.addAbsoluteTimerFuture[func;when]`: Run `func` at `when`, but only if it's in the future.
* `.finos.timer.addRelativeTimer[func;delay]`: Run `func` after `delay`.
* `.finos.timer.addPeriodicTimer[func;period]` Run `func` every `period` (first run is after `period` is elapsed once).
* `.finos.timer.addPeriodicTimerWithStartTime[func;when;period]`: Run `func` at `when` and then every `period` afterwards.
* `.finos.timer.addTimeOfDayTimer[func;startTime;period]`: Run `func` at `startTime` (must be a time or timespan) and then every `period` afterwards. `startTime` is today, unless that would put it in the past, in which case it's tomorrow. Most useful for setting a daily timer that should run at a certain time of day.
* `.finos.timer.removeTimer[tid]`: Remove a timer.
* `.finos.timer.adjustPeriodicFrequency[tid;newperiod]`: Change the `period` of a timer. This can turn a pending one-shot timer into a periodic one, and vice versa by setting the period to null.
* `.finos.timer.replaceCallback[tid;function]`: Replaces the callback function for a timer.
* `.finos.timer.setCatchUpMode[tid;mode]`: Sets the catch up mode for a timer. The default value can be set via the variable `.finos.timer.defaultCatchUpMode`. The mode has the following possible values:
  * ``` `none```: ignore the missed invocation - timer will run at the next occurrence
  * ``` `once```: trigger missed invocations but multiple missed invocations are only triggered once
  * ``` `all```: trigger all missed invocations - should only be used if the slowness is temporary and further invocations can indeed catch up
* `.finos.timer.list[]`: Get the list of all timers.

The timer is invoked with a dictionary containing the following fields:
* `id`: timer ID (int)
* `when`: scheduled time (timestamp)
* `func`: the function itself as it was registerd
* `period`: the timer period (timespan)
* `catchUpMode`: see `.finos.timer.setCatchUpMode` above (symbol)
