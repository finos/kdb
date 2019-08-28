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
