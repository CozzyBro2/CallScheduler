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
