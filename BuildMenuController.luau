-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES --
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local ItemsFolder = ReplicatedStorage:WaitForChild("Items")
local UITemplatesFolder = ReplicatedStorage:WaitForChild("UITemplates")

-- --
local SharedModule = require(ReplicatedStorage:WaitForChild("SharedModule"))
local AudioManager = require(ModulesFolder:WaitForChild("AudioManager"))
local GuiManager = require(ModulesFolder:WaitForChild("GUIManager"))

-- --
local BuildMenu = GuiManager.GetGui("BuildMenu")
local BottomBarFrame : Frame = BuildMenu:WaitForChild("BottomBar")
local ItemSelectFrame : Frame = BuildMenu:WaitForChild("ItemSelect")
local SelectButton : TextButton = BottomBarFrame:WaitForChild("Select")
local DeleteButton : TextButton = BottomBarFrame:WaitForChild("Delete")

-- --
local CategoryButtonTemplate = UITemplatesFolder:WaitForChild("CategoryButtonTemplate")
local ItemSelectTemplate = UITemplatesFolder:WaitForChild("ItemSelectTemplate")

-- --
local ItemSelectOpenPos = UDim2.new(0.5, 0,0.86, 0)
local ItemSelectClosePos = UDim2.new(0.5, 0,1.5, 0)
local ItemSelectMenuOpen = false

-- --
local BottomBarOpenPos = UDim2.new(0.5, 0,0.968, 0)
local BottomBarClosedPos = UDim2.new(0.5, 0,1.5, 0)

-- --
local CurrentToolTip

-- --
local Categories = {}
local ItemButtonConnections = {}
local BuildMenuController = {}

-- METHODS --
function BuildMenuController.OnStart()
	BuildMenuController.HideBottomBar()
	
	--
	BuildMenuController.ConstructCategories()
	BuildMenuController.ControlBottomBar()
	
	--
	ItemSelectFrame.Position = ItemSelectClosePos
end

-- --
function BuildMenuController.ControlBottomBar()
	for index, category in Categories do		
		local newButton = CategoryButtonTemplate:Clone()
		newButton.Parent = BottomBarFrame
		newButton.Label.Text = index
		
		--
		newButton.Activated:Connect(function()
			BuildMenuController.ShowItemSelectMenu(index)
			
			--
			AudioManager.PlaySoundLocal("UIClick")
		end)
		
		newButton.MouseEnter:Connect(function()
			AudioManager.PlaySoundLocal("UIHover")
		end)
	end
	
	--
	SelectButton.Activated:Connect(function()
		AudioManager.PlaySoundLocal("UIClick")
		
		--
		SharedModule.GetController("PlacementController").Exit()
		SharedModule.GetController("PlacementController").SetDeleteState(false)
		
		--
		BuildMenuController.HideItemSelectMenu()
	end)
	
	SelectButton.MouseEnter:Connect(function()
		AudioManager.PlaySoundLocal("UIHover")
	end)
	
	--
	DeleteButton.Activated:Connect(function()
		AudioManager.PlaySoundLocal("UIClick")
		
		--
		SharedModule.GetController("PlacementController").SetDeleteState(true)
		
		--
		BuildMenuController.HideItemSelectMenu()
	end)
	
	DeleteButton.MouseEnter:Connect(function()
		AudioManager.PlaySoundLocal("UIHover")
	end)
end

function BuildMenuController.ShowItemSelectMenu(categoryName : string)
	ItemSelectFrame:TweenPosition(ItemSelectOpenPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25)
	
	--
	for _, connection in ItemButtonConnections do
		connection:Disconnect()
	end
	
	--
	for _, child in ItemSelectFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	--
	local category = Categories[categoryName]
	
	--
	for index, item in category do
		local newFrame = ItemSelectTemplate:Clone()
		newFrame.Parent = ItemSelectFrame
		newFrame.ItemName.Text = item:GetAttribute("ItemName")
		
		--
		ItemButtonConnections[item.Name .. "Click"] = newFrame.Detect.Activated:Connect(function()
			SharedModule.GetController("PlacementController").Enter(item.Name)
		end)
	end
	
	--
	ItemSelectMenuOpen = true
end

function BuildMenuController.HideItemSelectMenu()
	ItemSelectFrame:TweenPosition(ItemSelectClosePos, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25)
	
	ItemSelectMenuOpen = false
end

function BuildMenuController.ShowBottomBar()
	BottomBarFrame:TweenPosition(BottomBarOpenPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quart)
end

function BuildMenuController.HideBottomBar()
	BottomBarFrame:TweenPosition(BottomBarClosedPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quart)
end

-- --

-- --
function BuildMenuController.ConstructCategories()
	for _, child in ItemsFolder:GetChildren() do
		Categories[child.Name] = child:GetChildren()
	end
end

-- --
--function BuildMenuController.OnUpdate(deltaTime : number)
--	if not CurrentToolTip then return end
	
--	--
	
--end

return BuildMenuController
