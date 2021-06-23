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

* Uncontrollable, and relatively unpredictable problematic throttling: `wait()` and `delay()` are [both tied to the ROBLOX Task Scheduler](https://imgur.com/a/ZQACsI4). They each impact it some, but more importantly; when the scheduler is under load these functions will begin to throttle and execution time of your threads / calls will begin to take a noticable hit in accuracy. (This is why you see some people in the roblox community go on about how `spawn()` and `wait()` should not be used large scale because they may just refuse to run or take far longer than intended to run.) You cannot control this behavior aside from just putting less work on the scheduler, granted you cannot control this behavior with my module either; however there is no throttling implemented by default as you will almost never need it, but you can add this functionality yourself if you desire. 

* Outdated / redundant approach to 'scheduling': `wait()` and `delay()` do not exactly have a very ergonomic approach to resuming / executing what you schedule, for `wait()` this is resuming a paused thread, and for `delay()` this is calling a newly created thread. In `wait()`'s case, this behavior is extremely redundant because it forces the need to workaround this force-yielding behavior through things like creating new threads, or relying on events (if applicable) to handle it for you. In `delay()`'s case, it forcibly spawns your thread. The impact of this is much less pronounced on the caller's side (yours), but still has a bit of a performance toll and is generally redundant behavior.
Comparatively, my module's approach to the way what you schedule is executed; is a little bit less encapsulated than roblox's functions. By default, it will just call the function you feed it. Because it uses generic call syntax, this means you can feed it a function wrapped by `coroutine.wrap` and consequently control if you want to yield or not, this is mostly just a niche case but it's a good thing to have. 

* Lack of customizability: Again, this comes down to how `wait()` and `delay()` just lack any form of interface, this is not ideal for when trying to appease the use cases of a whole platform. With this module, the customizability is being able to control exactly if something is scheduled or not, and being able to precisely control whether your call will be spawned on a new thread. 

## What performance / usability boost can I expect?

`CallScheduler` is not oriented around a boost in performance, but if that's partially or just what you're here for; this module offers a significant speedup to the execution of what you schedule, due to relying solely on calls, compared to resuming a yielded thread (typically a call in itself), or resuming a wrapped call.

In terms of usability, this was loosely mentioned in some detail in the 'Why' section, but `CallScheduler` can help keep your codebase much tidier due to how much control you have over it. Some examples in particular:

* No need to spawn a new thread to account for `wait()`'s yielding, this can be a bit tidier in some cases. 

And arguably most importantly, (so important it wasn't listed in the bulletpoints 😀) This allows you to pass arguments to your call directly in the `Scheduler.Add` function itself! Putting this into perspective, instead of having to do this:

```lua
delay(2, function()
    ImportantFunction(Important, StillImportant)
end)
```

You could just do this:

```lua
Scheduler.Add(2, ImportantFunction, Important, StillImportant)
```
*small performance footnote here, the top method means that idiomatic method calls can be done, e.g: `SomeClass:Method(..)` which [luaU incorporates optimizations for](https://luau-lang.org/performance#fast-method-calls). Compared to the bottom method which is less explicit, so in rare cases you could be trading some performance for small amount of readability (saving construction of function literal)*

This allows for slightly cleaner code when your 'schedule' is compacted with other function based code, or various other use cases where smaller == better.

Moving on to another significant example, say you have a while wait() loop that increments the stamina for every player by a little bit, and you have a module to control the state of this, `wait()` and `delay()` are not good at use cases like this:

```lua
local Module = {}
local Active

local function StartRunning()
    Active = true
    
    while Active do
        -- increment stamina here
        
        wait(0.5)
    end
end

function Module.Start(...)
    (...)

    coroutine.wrap(StartRunning)()
end

function Module.Stop(...)
    (...)
    
    Active = false
end

return Module
```
There's a bit of a problem with this code, when `Active` is set to false, the change does not reflect until the next `wait(0.5)` finishes, this introduces a small amount of redundant time checks in between those two points, and is a less elegant solution to controlling the state of a game mechanic. 

`CallScheduler` embraces this and can easily integrate with this sort of approach:
```lua
local Module = {}
local Scheduler = require(EpicModule)

local function IncrementStamina()
    Scheduler.Add(0.5, IncrementStamina)
    
    -- increment stamina here
end

function Module.Start(...)
    (...)

    IncrementStamina()
end

function Module.Stop(...)
    (...)
    
    Scheduler.Remove(IncrementStamina)
end

return Module
```
This code has none of the caveats you'd run into with using `wait()` or `delay()` here. Granted this isn't the most common use case, but it is still important to note when you could be having much more consice code thanks to this. 

## About Accuracy

The elephant in the room, but also not really. It is definetly very important to know whether something is accurate or not, and to that I can tell you that there is not much measurable difference between the two. If you scheduled up something random 2 or 5 times for about 1 second and then compared the execution times, they'd probably be extremely close. Both of these check the current timestamp in relation to the date of their scheduled functions every frame, although obviously `wait()` is bounded to a minimum execution time of 0.03 which changes based on throttling conditions. And that's exactly the difference, throttling. That's why if you care so much about accuracy, you may prefer this module due to lack of throttling. 

# That's everything.

I'll probably add more about this module sometime in the future, feel free to pull request or post an issue if you've got anything to say or changes to try and push. 
