-- SERVICES --
local ServerStorage = game:GetService("ServerStorage")
local DataService = require(ServerStorage.Services.DataService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HTTPService = game:GetService("HttpService")

-- VARIABLES --
local ItemsFolder = ReplicatedStorage.Items
local PlayerValuesFolder = ReplicatedStorage.PlayerValues
local TycoonModule = require(ServerStorage.Modules.Tycoon)
local RemotesFolder = ReplicatedStorage.Remotes
local PlotsFolder = workspace.Plots

-- --
local UpdateInventoryRemote = RemotesFolder.UpdateInventory
local UpdatePlotRemote = RemotesFolder.UpdatePlot
local PlaceItemRemote = RemotesFolder.PlaceItem
local NewGameRemote = RemotesFolder.NewGame
local LoadGameRemote = RemotesFolder.LoadGame
local MoveItemRemote = RemotesFolder.MoveItem
local DeleteItemRemote = RemotesFolder.DeleteItem

-- --
local PlayerTycoons = {}

-- --
local TycoonService = {}

-- --
TycoonService.GlobalMultiplier = 1

-- METHODS --
function TycoonService.OnStart()
	PlaceItemRemote.OnServerInvoke = function(player : Player, itemName : string, cframe : CFrame)
		if not ItemsFolder:FindFirstChild(itemName, true) then return "This item does not exist." end
		if not TycoonService.PlayerOwnsItem(player, itemName) then return "You haven't unlocked ths item." end
		if not TycoonService.PlayerCanAffordItem(player, itemName) then return "You canno't afford this item." end
		
		--
		local ID = tostring(HTTPService:GenerateGUID(false))
		
		--
		local relativeCFrame : CFrame = TycoonService.GetPlotBase(player).CFrame:Inverse() * cframe
		local saveInformation = {
			["ItemName"] = itemName,
			["CFrameComponents"] = TycoonService.GetCFrameComponents(relativeCFrame),
			["ID"] = ID
		}
		
		--
		DataService.AddPlacedItem(player, ID, saveInformation)
		
		--
		local clone = ItemsFolder:FindFirstChild(itemName, true):Clone()
		clone.Parent = PlayerTycoons[player].Plot.Items
		clone:PivotTo(cframe)
		clone:SetAttribute("ID", ID)
		
		--
		TycoonService.RemoveCash(player, clone:GetAttribute("Price"))
		--TycoonService.RemoveItemFromInventory(player, itemName, 1)
		
		--
		return "Success"
	end
	
	--
	MoveItemRemote.OnServerInvoke = function(player : Player, itemID : number, cframe : CFrame)
		local item = TycoonService.GetPlacedItemByID(player, itemID)
		if not item then return "Item not found, report to developers" end
		
		--
		local data = DataService.GetData(player)
		local placedItems = data["PlacedItems"]
		
		--
		for index, item in placedItems do
			if item.ID == itemID then
				local relativeCFrame : CFrame = TycoonService.GetPlotBase(player).CFrame:Inverse() * cframe
				
				--
				item.CFrameComponents = TycoonService.GetCFrameComponents(relativeCFrame)
				
				break
			end
		end
		
		--
		DataService.SetKeyValue(player, "PlacedItems", placedItems)
		
		--
		item:PivotTo(cframe)
		
		--
		return "Success"
	end
	
	--
	DeleteItemRemote.OnServerInvoke = function(player : Player, itemID : number)
		local item = TycoonService.GetPlacedItemByID(player, itemID)
		if not item then return "Item not found, report to developers" end
		
		--
		--DataService.EraseKeyValue(player, "PlacedItems", itemID)
		DataService.RemovePlacedItem(player, itemID)
		TycoonService.AddCash(player, item:GetAttribute("Price"))
		item:Destroy()
		
		--
		return "Success"
	end
	
	--
	NewGameRemote.OnServerInvoke = function(player : Player)
		DataService.ResetData(player)
		
		--
		TycoonService.SendPlayerToPlot(player)
		TycoonService.LoadTycoon(player)
		
		--
		return "Success"
	end
	
	--
	LoadGameRemote.OnServerInvoke = function(player : Player)
		TycoonService.SendPlayerToPlot(player)
		
		--
		TycoonService.LoadTycoon(player)
		
		--
		return "Success"
	end
end

function TycoonService.PlayerJoined(player : Player)
	PlayerTycoons[player] = { Owner = player, Plot = TycoonService.GetRandomPlot(player) }
	
	--
	local newPlayerValue = Instance.new("NumberValue")
	newPlayerValue.Name = player.Name
	newPlayerValue.Parent = PlayerValuesFolder
	
	print(DataService.GetKeyValue(player, "Cash"))
	
	--
	TycoonService.UpdatePlayerValues(player)
	TycoonService.UpdateClient(player)
end

function TycoonService.PlayerLeft(player : Player)
	if PlayerTycoons[player] then
		local plot = PlayerTycoons[player].Plot
		local items = plot.Items
		
		--
		plot.Items:ClearAllChildren()
		plot.Owner.Value = nil
		
		--1783680012
		
		--
		PlayerTycoons[player] = nil
	end
	
	--
	if PlayerValuesFolder:FindFirstChild(player.Name) then
		PlayerValuesFolder:FindFirstChild(player.Name):Destroy()
	end
end

function TycoonService.GetTycoon(player : Player)
	return PlayerTycoons[player]
end

--
function TycoonService.GetPlotBase(player : Player)
	return PlayerTycoons[player].Plot.Base
end

function TycoonService.GetPlotItemsFolder(player : Player)
	return PlayerTycoons[player].Plot.Items
end

function TycoonService.GetPlotSpawn(player : Player)
	return PlayerTycoons[player].Plot.Spawn
end

function TycoonService.SendPlayerToPlot(player : Player)
	local spawnLocation : SpawnLocation = TycoonService.GetPlotSpawn(player)
	local cframe : CFrame = spawnLocation.CFrame * CFrame.new(0, 5, 0)
	
	--
	player.Character:PivotTo(cframe)
end

-- --
function TycoonService.GetPlacedItemByID(player : Player, itemID : number)
	for _, child in PlayerTycoons[player].Plot.Items:GetChildren() do
		if child:GetAttribute("ID") == itemID then
			return child
		end
	end
end

-- --
function TycoonService.LoadTycoon(player : Player)
	local data = DataService.GetData(player)
	local placedItems = data["PlacedItems"]
	
	--
	for _, item in placedItems do
		local cframeComponents = item.CFrameComponents
		local savedCFrame : CFrame = TycoonService.GetCFrameFromComponents(cframeComponents)
		local newCFrame : CFrame = TycoonService.GetPlotBase(player).CFrame * savedCFrame
		
		--
		local newItem = ItemsFolder:FindFirstChild(item.ItemName, true):Clone()
		newItem:PivotTo(newCFrame) -- CONVERT THIS CFRAME TO ANY PLOT!!!
		newItem.Parent = TycoonService.GetPlotItemsFolder(player)
		newItem:SetAttribute("ID", item.ID)
	end
end

-- --
function TycoonService.AddItemToInventory(player : Player, itemName : string, amount : number?)
	local data = DataService.GetData(player)
	local inventory = data.Inventory
	
	--
	if inventory then
		if inventory[itemName] then
			inventory[itemName] += amount or 1
		else
			inventory[itemName] = 1
		end
	end
	
	--
	DataService.SetKeyValue(player, "Inventory", inventory)
	TycoonService.UpdateClient(player)
end

function TycoonService.RemoveItemFromInventory(player : Player, itemName : string, amount : number?)
	local data = DataService.GetData(player)
	local inventory = data.Inventory

	--
	if inventory then
		if inventory[itemName] then
			inventory[itemName] -= amount or 1
		end
	end

	--
	DataService.SetKeyValue(player, "Inventory", inventory)
	TycoonService.UpdateClient(player)
end

function TycoonService.AddCash(player : Player, Amount : number)
	DataService.IncrementNumber(player, "Cash", Amount)
	
	--
	TycoonService.UpdateClient(player)
	TycoonService.UpdatePlayerValues(player)
end

function TycoonService.RemoveCash(player : Player, Amount : number)
	DataService.IncrementNumber(player, "Cash", -Amount)
	
	--
	local currentCash = DataService.GetKeyValue(player, "Cash")
	
	--
	if currentCash <= 0 then
		DataService.SetKeyValue(player, "Cash", 0)
	end
	
	--
	TycoonService.UpdatePlayerValues(player)
	TycoonService.UpdateClient(player)
end

function TycoonService.SetMultiplier(player : Player, newMultiplier : number)
	DataService.SetKeyValue(player, "Multiplier", newMultiplier)
	
	--
	TycoonService.UpdatePlayerValues(player)
	TycoonService.UpdateClient(player)
end

function TycoonService.SetGlobalMultiplier(newMultiplier : number)
	TycoonService.GlobalMultiplier = newMultiplier
end

function TycoonService.PlayerOwnsItem(player : Player, itemName : string) : boolean
	local playerLevel : number = DataService.GetKeyValue(player, "Level")
	local itemLevel : number = ItemsFolder:FindFirstChild(itemName, true):GetAttribute("MaxLevel")
	
	--
	return playerLevel >= itemLevel
end

function TycoonService.PlayerCanAffordItem(player : Player, itemName : string) : boolean
	local playerCash : number = DataService.GetKeyValue(player, "Cash")
	local itemPrice : number = ItemsFolder:FindFirstChild(itemName, true):GetAttribute("Price")
	
	--
	return playerCash > itemPrice	
end

-- --
function TycoonService.GetRandomPlot(player : Player)
	for _, plot in PlotsFolder:GetChildren() do
		local ownerValue = plot.Owner
		
		if ownerValue and ownerValue.Value == nil then
			ownerValue.Value = player
			
			--
			print("[TycoonService] ->", player.Name, "has been assigned to plot", plot.Name)
			
			--
			return plot
		end
	end
end

function TycoonService.GetCFrameComponents(cframe : CFrame)
	return {cframe:GetComponents()}
end

function TycoonService.GetCFrameFromComponents(cframeComponents : {})
	return CFrame.new(unpack(cframeComponents))
end

-- --
function TycoonService.UpdateClient(player : Player)
	UpdatePlotRemote:FireClient(player, TycoonService.GetPlotBase(player))
	UpdateInventoryRemote:FireClient(player, DataService.GetKeyValue(player, "Inventory"))
end

function TycoonService.UpdatePlayerValues(player : Player)
	if PlayerValuesFolder:FindFirstChild(player.Name) then
		PlayerValuesFolder:FindFirstChild(player.Name).Value = DataService.GetKeyValue(player, "Cash")
	end
end

-- --
return TycoonService
