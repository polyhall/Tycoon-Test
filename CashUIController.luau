-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

-- VARIABLES --
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local PlayerValuesFolder = ReplicatedStorage:WaitForChild("PlayerValues")

-- MODULES --
local GUIManager = require(ModulesFolder:WaitForChild("GUIManager"))

-- --
local HUDGui = GUIManager.GetGui("HUD")
local MainFrame : Frame = HUDGui:WaitForChild("Main")
local CashFrame : Frame = MainFrame:WaitForChild("CashFrame")
local CashLabel : TextLabel = CashFrame:WaitForChild("CashLabel")

-- --
local PlayerCashValue : NumberValue = nil

-- --
local CashUIController = {}

-- METHODS --
function CashUIController.OnStart()
	PlayerCashValue = PlayerValuesFolder:WaitForChild(PlayerService.LocalPlayer.Name, 999)
	
	--
	repeat task.wait() until PlayerCashValue ~= nil
	
	--
	CashLabel.Text = GUIManager.FormatNumberToCash(PlayerCashValue.Value)
	
	--
	PlayerCashValue.Changed:Connect(function(newValue : number)
		CashLabel.Text = GUIManager.FormatNumberToCash(newValue)
	end)
end

return CashUIController
