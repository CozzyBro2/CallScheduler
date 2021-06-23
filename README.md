# CallScheduler
Roblox module that allows accurate scheduling of lua functions (calls) with more digestible syntax when compared to alternatives.

## Notes

* Detached from `lua-stuff` for easy editing, and I felt it deserved it's own repo.
* Use the cool github pages site to read about this creation: https://cozzybro2.github.io/CallScheduler/
* If you care at all for some reason, this is intended to replace `delay()` moreso than it is to replace `wait()`.

## Why CallScheduler?

CallScheduler is a module I created to address a few caveats with the default roblox functions that achieve something similar; (e.g `wait()`, `delay()`)
I won't go too into specifics because this isn't a rant, but I will address some of the glaring issues with those functions:

* Lack of flexiblity: `wait()` and `delay()` are stand-alone functions, you cannot in *any* way interact with their internal state, this means that any usage outside of "schedule & forget" will be difficult, if not impossible to achieve, this module addresses that by providing a mutable internal state exposed through two module functions: `Scheduler.Add()` and `Scheduler.Remove()`. 

* Uncontrollable, and relatively unpredictable problematic throttling: `wait()` and `delay()` are [both tied to the ROBLOX Task Scheduler](https://imgur.com/a/ZQACsI4). They each impact it some, but more importantly; when the scheduler is under load these functions will begin to throttle and execution time of your threads / calls will begin to take a noticable hit in accuracy. (This is why you see some people in the roblox community go on about how `spawn()` and `wait()` should not be used large scale because they may just refuse to run i.e infinite throttling) You cannot control this behavior aside from just putting less work on the scheduler, granted you cannot control this behavior with my module either; however there is no throttling implemented by default as you will almost never need it, but you can add this functionality yourself if you desire. 

* Outdated / redundant approach to 'scheduling': `wait()` and `delay()` do not exactly have a very ergonomic approach to resuming / executing what you schedule, for `wait()` this is resuming a paused thread, and for `delay()` this is calling a newly created thread. In `wait()`'s case, this behavior is extremely redundant because it forces the need to workaround this force-yielding behavior through things like creating new threads, or relying on events (if applicable) to handle it for you. In `delay()`'s case, it forcibly spawns your thread. The impact of this is much less pronounced on the caller's side (yours), but still has a bit of a performance toll and is generally redundant.
