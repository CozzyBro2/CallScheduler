local Scheduled   = {} -- { Info = os.clock }
local ScheduleMap = {} -- { Callback = Info }
local Scheduler   = {Jitter = 0.005}

game:GetService("RunService").Heartbeat:Connect(function()
	for Info, Date in pairs(Scheduled) do
		if os.clock() < Date then continue end

		local Call = Info.Call
		Scheduler.Remove(Call)

		Call(unpack(Info.Args))
	end
end)

function Scheduler.Add(Time, Callback, ...)
	assert(Time, "Invalid argument #1 'Time'"); assert(Callback, "Invalid argument #2 'Callback'")

	local Info = ScheduleMap[Callback] or {
		Call = Callback, 
		Args = {...}
	}

	Scheduled[Info] = (os.clock() + Time) - Scheduler.Jitter
	ScheduleMap[Callback] = Info
end

function Scheduler.Remove(Callback)
	local ToRemove = ScheduleMap[Callback]

	Scheduled[ToRemove] = nil
	ScheduleMap[Callback] = nil
end

return Scheduler
