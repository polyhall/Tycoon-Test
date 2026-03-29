-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES --
local SoundsFolder = ReplicatedStorage:WaitForChild("Sounds")

local AudioManager = {}

-- METHODS --
function AudioManager.PlaySoundInstance(soundInstance : Sound)
	local newSound = soundInstance:Clone()
	newSound.Parent = workspace.CurrentCamera
	
	--
	task.spawn(function()
		newSound:Play()
		newSound.Ended:Wait()
		newSound:Destroy()
	end)
end

-- --
function AudioManager.PlaySoundLocal(soundName : string)
	if not SoundsFolder:FindFirstChild(soundName) then return end
	
	--
	AudioManager.PlaySoundInstance(SoundsFolder:FindFirstChild(soundName))
end

return AudioManager
