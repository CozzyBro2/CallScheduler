# CallScheduler
Roblox module that allows accurate scheduling of lua functions (calls) with more digestible syntax when compared to alternatives.

## Notes

* Detached from `lua-stuff` for easy editing, and I felt it deserved it's own repo.

* Use the cool github pages site to read about this creation: https://cozzybro2.github.io/CallScheduler/ (W.I.P)

* There is a seperate version of this module available at: `src/OptimizedCallScheduler.lua` which implements a pretty minor, but additive optimization which can improve frametimes by not indexing the 'Call Date' for every scheduled function that is not ready to be called. In other words, if you're using this module on a significantly large scale, you should go with the optimized version. (Note that I may not maintain it as actively as the original)

* This is not intended to be an 'end-all' replacement for default roblox functions, this module is new and many kinks in it's functionality may not have been yet discovered, or are in progress of being resolved. Support / reliability are provided on a 'best-effort' basis. By using this module you accept that I am not liable for any mishaps in gameplay that may arise from this fact.

# How do I use it?

Grab the source code from `src/CallScheduler.lua`, and put it in ReplicatedStorage. Then you can require it, and use the variables it exposes through the module table:

```
Scheduler.Add(Time: number, Callback: function, ...)

Scheduler.Remove(Callback: function)

Scheduler.Jitter = 0.005
```
Here is some example code:

```lua
-- Code Sample: A normal schedule

local Scheduler = require(...)

local function SomeFunction()

end

Scheduler.Add(2, SomeFunction) -- schedules 'SomeFunction' to be called 2 seconds from now
```
```lua
-- Code Sample: a recurring function (similar to while wait() do)

local Scheduler = require(...)

local function SomeFunction()
    Scheduler.Add(2, SomeFunction) -- re-scheduling itself

    -- Recurring task that happens every 2 seconds here
end

Scheduler.Add(2, SomeFunction) -- schedules 'SomeFunction' to be called 2 seconds from now

--- when it's time to stop it:

Scheduler.Remove(SomeFunction) -- stops it from running anymore, can always be restarted by using the above function
```

```lua
-- Code Sample: Yielding risk

local Scheduler = require(...)

local function YieldingFunction()
    SomeLongHttpCall()
end

Scheduler.Add(2, coroutine.wrap(YieldingFunction)) 
-- Call scheduler does not implement 'Thread Safety' you will need to wrap any function that can potentially yield to guarantee things get scheduled without delay.
```

## *Why* CallScheduler?

CallScheduler is a module I created to address a few caveats with the default roblox functions that achieve something similar; (e.g `wait()`, `delay()`)
I won't go too into specifics because this isn't a rant, but I will address some of the glaring issues with those functions:

* Lack of flexiblity: `wait()` and `delay()` are stand-alone functions, not libraries or anything like that. you cannot in *any* way interact with or customize their internal state, this means that any usage outside of "schedule & forget" will be more difficult to implement, this module addresses that by providing a mutable internal state exposed through two module functions: `Scheduler.Add()` and `Scheduler.Remove()`. 

* Uncontrollable, and relatively unpredictable throttling: `wait()` and `delay()` are [both tied to the ROBLOX Task Scheduler](https://imgur.com/a/ZQACsI4). When the scheduler is under load these functions will begin to throttle and execution time of your threads / calls will begin to take a noticable hit in accuracy. (The foundation of the "spawn and wait never run" argument.) 

You cannot control this behavior aside from just putting less work on the scheduler, and the behavior is hardly necessary as the performance benefit gained through throttling in any normal case is usually negligible. There is no throttling implemented by default in `CallScheduler`, because as mentioned previously you will almost never need it, but you can add this functionality yourself if you desire. 

* More redundant approach to 'scheduling': `wait()` and `delay()` do not exactly have a very ergonomic approach to resuming / executing what you schedule, for `wait()` this is resuming a paused thread, and for `delay()` this is calling a newly created thread. In `wait()`'s case, this behavior is extremely redundant because it forces the need to workaround this force-yielding behavior through things like creating new threads, which can measurably increase code complexity and slow things down large scale.

In `delay()`'s case, it forcibly spawns your thread. The impact of this is much less pronounced on the caller's side (yours), but still has a bit of a performance toll and is generally redundant behavior.

Comparatively, my module's approach to this is a little bit less hidden. By default, it will just call the function you feed it, because it uses generic call syntax. this means you can feed it a function wrapped by `coroutine.wrap` and consequently control if you want to yield or not. (Applies to anything that can be called using `()` call syntax)  

* Lack of customizability: As mentioned earlier, you can't customize `wait()` and `delay()` at all, this module provides customizability in the form of mutable state (see bulletpoint 1), and the ability to change the 'jitter' (`delay()` also implements a jitter, but you can't change it.) There's also some scalability given from the open-endedness of this module. You can add what you want if need be, throttling, etc. 

# What performance / usability boost can I expect?

`CallScheduler` is not oriented around a boost in performance. But 'calls' themselves in LuaU are very fast, fast enough to outperform resuming yielded threads. (as of writing this. this also applies to `coroutine.wrap`)

If anything, you may introduce a little bit of CPU complexity due to having two forms of scheduler running in the background (`wait()` and `CallScheduler`). But so long as `wait()` is not used by you, the difference should be negligible enough to not have to worry over. 

The main benefit that comes from using this module is usability. With `wait()`, you will have to create new coroutined functions somewhere to account for the yielding, `delay()` will also usually require the construction of a literal instead, due to not being able to pass arguments. 

Yes, you read right. You can pass arguments into the `Scheduler.Add()` function, to put this into perspective, instead of having to do this:

```lua
delay(2, function()
    ImportantFunction(Important, StillImportant)
end)
```

You could just do this:

```lua
Scheduler.Add(2, ImportantFunction, Important, StillImportant)
```
*small performance footnote here, the top method means that idiomatic method calls can be done, e.g: `SomeClass:Method(..)` which [LuaU incorporates optimizations for](https://luau-lang.org/performance#fast-method-calls). Compared to the bottom method which is less explicit, so in rare cases you could be trading some performance for small amount of readability (saving construction of function literal)*

This allows for slightly smaller code, which is often desirable for readability.

Moving on to another significant example, say you have a `while wait(0.5)` loop that increments the stamina for every player by a little bit, and you have a module to control the state of this mechanic, `wait()` and `delay()` won't help you much here because they lack the aforementioned gimmick:

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
The problem with this code, is when `Active` is set to false, the change does not reflect until the next `wait(0.5)` finishes, this introduces a small amount of redundant time checks until that point is reached. And is overall, a less elegant solution to controlling the state of a game mechanic. 

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
This code does not have the redundant time check quirk, and if for whatever reason the `IncrementStamina` function ever needed some arguments; the scalability is there. That's why I would recommend you use this module.

## About Accuracy

There is not much difference between `CallScheduler`, `wait()` and `delay()` in terms of accuracy. If you scheduled up a random function 2 or 5 times each for 1 second, and then compared the execution times; they'd probably be identical. All of these methods the current timestamp in relation to the date of their scheduled functions every frame, although `wait()` is bounded to a minimum execution time of 0.03 which changes based on throttling conditions. And that's exactly the difference, throttling. That's why if you care a lot about accuracy, you may prefer this module due to lack of inbuilt throttling. 

# That's everything.

I'll probably add more about this module sometime in the future, feel free to pull request or post an issue anytime.
