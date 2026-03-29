-- SERVICES --
local PlayerService = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- VARIABLES --
local Player = PlayerService.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Mouse = Player:GetMouse()

-- --
local ItemsFolder = ReplicatedStorage:WaitForChild("Items")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- --
local UpdateInventoryRemote = RemotesFolder:WaitForChild("UpdateInventory")
local UpdatePlotRemote = RemotesFolder:WaitForChild("UpdatePlot")
local PlaceItemRemote = RemotesFolder:WaitForChild("PlaceItem")
local MoveItemRemote = RemotesFolder:WaitForChild("MoveItem")
local DeleteItemRemote = RemotesFolder:WaitForChild("DeleteItem")

--
local AudioManager = require(ModulesFolder:WaitForChild("AudioManager"))
local UtilFunctions = require(script:WaitForChild("Util"))
local GUIManager = require(ModulesFolder:WaitForChild("GUIManager"))

-- --
local Inventory = {}
local PlacementController = {}

-- --
local Active = false
local CurrentModel = nil
local Moving = false
local Deleting = false
local Plot = nil
local GridSize = 0.5
local RotateIncrement = 90
local RotationCFrame = CFrame.new()
local CurrentPick = nil
local CurrentHover = nil

--
function PlacementController.OnStart()
	UpdatePlotRemote.OnClientEvent:Connect(function(newPlot)
		Plot = newPlot
		--print("[Placement Controller] -> Plot recieved")
	end)
	
	UpdateInventoryRemote.OnClientEvent:Connect(function(newInventory)
		Inventory = newInventory
		--print("[Placement Controller] -> New Inventory Recieved")
	end)
	
	UserInputService.InputBegan:Connect(function(inputObject : InputObject, gameProcessed : boolean)	
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			if gameProcessed then return end
			
			if Active then
				PlacementController.Place()
			else
				PlacementController.Pick()
			end
		end
		
		--
		if inputObject.KeyCode == Enum.KeyCode.R then
			if not Active then return end
			
			--
			PlacementController.Rotate()
		end
	end)
end

--
function PlacementController.Enter(itemName : string)
	if not Plot then return end
	
	--
	if CurrentModel then
		CurrentModel:Destroy()
	end
	
	PlacementController.SetCurrentModel(itemName)
	
	--
	Active = true
end

function PlacementController.Exit()
	if CurrentModel then CurrentModel:Destroy() end
	
	--
	if CurrentPick then
		CurrentPick.Parent = Plot.Parent.Items
	end
	
	--
	CurrentModel = nil
	CurrentPick = nil
	
	--
	Moving = false
	Active = false
end

function PlacementController.Place()
	if not Plot then return end
	if not CurrentModel then return end
	
	--
	if not UtilFunctions.IsPositionValid(CurrentModel, Plot) then
		AudioManager.PlaySoundLocal("PlaceItemFail")
		return
	end

	
	--
	local cframe : CFrame = CurrentModel:GetPivot()

	--
	if Moving then
		local attempt : string = MoveItemRemote:InvokeServer(CurrentPick:GetAttribute("ID"), cframe)
		
		if attempt == "Success" then
			PlacementController.Exit()
		end
		
		--
		return
	end

	--
	local attempt : string = PlaceItemRemote:InvokeServer(CurrentModel.Name, cframe) -- make this server authorative
	
	--
	if attempt ~= "Success" then
		print("[Placement Controller] -> Error placing item for: ", attempt)
		AudioManager.PlaySoundLocal("PlaceItemFail")
		return
	end
	
	--
	GUIManager.PlaceCashText(cframe, CurrentModel:GetAttribute("Price"))
	
	
	--
	AudioManager.PlaySoundLocal("PlaceItem")
end

function PlacementController.Pick()
	if not Plot then return end
	if not Mouse.Target then return end
	if not Mouse.Target:IsDescendantOf(Plot.Parent.Items) then return end
	
	--
	if Deleting then
		DeleteItemRemote:InvokeServer(Mouse.Target.Parent:GetAttribute("ID"))
		return
	end
	
	--
	CurrentPick = Mouse.Target.Parent
	CurrentPick.Parent = ReplicatedStorage
	
	--
	PlacementController.SetCurrentModel(CurrentPick.Name)
	PlacementController.ApplyPreviewMaterial()
	
	--
	Active = true
	Moving = true
end

function PlacementController.Hover()
	if not Plot then return end
	
	--
	--if Mouse.Target then
	--	if Mouse.Target:IsDescendantOf(Plot.Parent.Items) then
	--		CurrentHover = Mouse.Target.Parent
	--	end
	--end
	
	----
	--if CurrentHover then
	--	UtilFunctions.UpdateHighlight(CurrentHover, false, Deleting)
	--end
end

-- --
function PlacementController.SetDeleteState(newState : boolean)
	Deleting = newState
end

--
function PlacementController.ApplyPreviewMaterial()
	if not Plot then return end
	if not CurrentModel then return end

	--
	for _, child in CurrentModel:GetDescendants() do
		if child:IsA("BasePart") then
			if child ~= CurrentModel.PrimaryPart then
				child.Transparency = 0.1
			end
			
			child.CanCollide = false
			child.Anchored = true
			child.CanQuery = false
			--child.CanTouch = false
		end
	end
end

function PlacementController.SetCurrentModel(itemName : string)
	if not Plot then return end
	if not ItemsFolder:FindFirstChild(itemName, true) then return end

	--
	if CurrentModel then CurrentModel:Destroy() end
	
	--
	CurrentModel = ItemsFolder:FindFirstChild(itemName, true):Clone()
	CurrentModel.Parent = workspace
	
	--
	PlacementController.ApplyPreviewMaterial()
end

function PlacementController.Rotate()
	RotationCFrame *= CFrame.Angles(0, math.rad(RotateIncrement), 0)
end

function PlacementController.OnUpdate(deltaTime : number)
	if not Active then PlacementController.Hover() return end
	if not Plot then return end
	if not CurrentModel then return end
	if not CurrentModel.PrimaryPart then return end
	
	--
	local mousePos = Mouse.Hit.Position
	local clampedPos = UtilFunctions.ClampToPlot(mousePos, Plot, CurrentModel, GridSize)
	local snappedPos = UtilFunctions.GetGridSnap(clampedPos, GridSize, CurrentModel, Plot)
	local positionValid = UtilFunctions.IsPositionValid(CurrentModel, Plot)
	
	--
	CurrentModel:PivotTo(CFrame.new(snappedPos) * RotationCFrame)
	
	--
	UtilFunctions.UpdateHighlight(CurrentModel, positionValid, Deleting)
end


--

return PlacementController
