if Task == nil then
  Task = class({})
end

Task.list = {}

--auto increment task ids
Task.taskCounter = 0

local TASK_DELAY = 1
local TASK_INTERVAL = 2
local TASK_INTERVAL_COUNT = 3

function Task:init()
  local GameMode = GameRules:GetGameModeEntity()
	GameMode:SetContextThink("Tasks", Task.OnThink, 0.03)
end


function Task:Delay(func, seconds, params)
  Task.taskCounter = Task.taskCounter + 1
  table.insert(Task.list, {
      type = TASK_DELAY,
      endTime = GameRules:GetGameTime() +seconds,
      func = func,
      params = params,
      id = Task.taskCounter,
      interupted = false
    }
  )
	return Task.taskCounter
end

--calls a function repeatitivly with a delay, returns the TaskID
function Task:Interval(func, seconds, params)
	Task.taskCounter = Task.tasksCounter + 1
	table.insert(Task.waitingTasks, {
    type = TASK_INTERVAL,
		endTime = GameRules:GetGameTime() + seconds,
		func = func,
		params = params,
		duration = secs,
		id = Task.taskCounter,
		interupted = false
	})
	return Task.taskCounter
end

--interupts a task and will return true if task was found with matching id
function Task:Interupt(taskID)
	local len = table.getn(Task.waitingTasks)
	for i=1, #Task.list do
		if Task.list[i].id == taskID then
			Task.list[i].interupted = true
			return true
		end
	end
	return false
end

function Task:OnThink()
  local now = GameRules:GetGameTime()

  local i=1
  while Task.list[i] ~= nil do
    --removed any interupted tasks
		if Task.list[i].interupted == true then
      table.remove(Task.list, i)
      i = i-1
    --if function is ready to be called
    elseif Task.list[i].endTime <= now then
      --call task
      Task.list[i].func(Task.list[i].params)
      

      --update Task.list and endTime
      if Task.list[i].type == TASK_INTERVAL then --interval
        Task.list[i].endTime = Task.list[i].endTime + Task.list[i].interval
      else --delay
        table.remove(Task.list, i)
        i = i-1
      end
    end
    i = i+1
  end
  

  return 0.03
end
