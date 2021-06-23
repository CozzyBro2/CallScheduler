local Scheduled = {} -- { Callback = Info }
local Scheduler = {Jitter = 0.005}

game:GetService("RunService").Heartbeat:Connect(function()
	for Call, Info in pairs(Scheduled) do
		if os.clock() < Info.Date then continue end

		Scheduler.Remove(Call)

		Call(unpack(Info.Args))
	end
end)

function Scheduler.Add(Time, Callback, ...)
	assert(Time, "Invalid argument #1 'Time'"); assert(Callback, "Invalid argument #2 'Callback'")
	
	local Info = {
		Date = (os.clock() + Time) - Scheduler.Jitter,
		Call = Callback, 
		Args = {...}
	}

	Scheduled[Callback] = Info
end

function Scheduler.Remove(Callback)
	Scheduled[Callback] = nil
end

return Scheduler
