-- SERVICES --
local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebrisService = game:GetService("Debris")

-- VARIABLES --
local Player = PlayerService.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- --
local UITemplatesFolder = ReplicatedStorage:WaitForChild("UITemplates")
local PlaceCashTemplate = UITemplatesFolder:WaitForChild("PlaceCashTemplate")

--
local GUIManager = {}

-- METHODS --
function GUIManager.GetGui(guiName : string) : ScreenGui
	return PlayerGui:FindFirstChild(guiName)
end

function GUIManager.ShowGui(guiName : string)
	GUIManager.GetGui(guiName).Enabled = true
end

function GUIManager.HideGui(guiName : string)
	GUIManager.GetGui(guiName).Enabled = true
end

function GUIManager.HideAllGUIS()
	for _, gui in PlayerGui:GetChildren() do
		if gui:IsA("ScreenGui") then
			gui.Enabled = false
		end
	end
end

--
function GUIManager.FormatNumberToCash(number : number) : string
	local formatted = string.format("%d", number):reverse():gsub("(%d%d%d)", "%1,"):reverse()

	--
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end

	-- 
	return "$" .. formatted
end

function GUIManager.PlaceCashText(cframe : CFrame, amount : number)
	local cashValue : string = GUIManager.FormatNumberToCash(amount)
	local template = PlaceCashTemplate:Clone()
	
	--
	local position, onScreen = workspace.CurrentCamera:WorldToScreenPoint(cframe.Position)

	--
	template.Parent = GUIManager.GetGui("HUD")
	template.Position = UDim2.new(0, position.X, 0, position.Y)
	template.Text = cashValue
	
	--
	DebrisService:AddItem(template, 5)
end

return GUIManager
