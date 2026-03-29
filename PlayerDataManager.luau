-- SERVICES --
local PlayerService = game:GetService("Players")
local DatastoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- VARIABLES --
local DATA_STORE_NAME = "TESTING1"
local AUTO_SAVE_INTERVAL = 60

-- --
local PlayerDataStore = DatastoreService:GetDataStore(DATA_STORE_NAME)
local PlayerData = {}
local DefaultData = {
	Cash = 1500,
	Level = 1,
	XP = 0,
	Multiplier = 1,
	PlacedItems = {},
	Inventory = {},
}

-- --
local DataService = {}

-- METHODS --
function DataService.PlayerJoined(player : Player)
	DataService.LoadData(player)
	
	--
	if RunService:IsStudio() then
		print(PlayerData[player])
	end
end

function DataService.PlayerLeft(player : Player)
	DataService.SaveData(player)
	
	--
	if PlayerData[player] then
		if RunService:IsStudio() then
			print(PlayerData[player])
		end
		
		--
		PlayerData[player] = nil
	end
end

function DataService.LoadData(player : Player)
	local key : string = "Player_" .. tostring(player.UserId)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(key)
	end)
	
	--
	if success and data then
		PlayerData[player] = data
	else
		PlayerData[player] = table.clone(DefaultData)
		print("[DataService] : -> No data found for " .. player.Name .. ", using default data.")
	end
end

function DataService.SaveData(player : Player)
	local key : string = "Player_" .. tostring(player.UserId)
	local data = PlayerData[player]
	
	--
	if data then
		local success, errorMessage = pcall(function()
			PlayerDataStore:SetAsync(key, data)
		end)
		
		--
		if not success then
			warn("[DataService] : ->", "Failed to save data for", player.Name, "(", errorMessage, ")")
		end
	end
end

-- --
function DataService.GetKeyValue(player : Player, key : string) : any?
	local data = PlayerData[player]
	
	--
	if data then
		if data[key] then
			return data[key]
		else
			warn("[DataService] -> Key (", key, ") does not exist in the data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
	
	--
	return nil
end

function DataService.SetKeyValue(player : Player, key : string, value : any?)
	local data = PlayerData[player]
	
	--
	if data then
		if data[key] then
			data[key] = value
		else
			warn("[DataService] -> Key (", key, ") does not exist in the data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
end

function DataService.EraseKeyValue(player : Player, key : string, value : any)
	local data = PlayerData[player]

	--
	if data then
		if data[key] then
			print(data[key][value])
		else
			warn("[DataService] -> Key (", key, ") does not exist in the data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
	
	--
	DataService.SaveData(player)
end

function DataService.InsertTableToKey(player : Player, key : string, tableToInsert)
	local data = PlayerData[player]
	
	--
	if data then
		if data[key] then
			table.insert(PlayerData[player][key], tableToInsert)
		else
			warn("[DataService] -> Key (", key, ") does not exist in the data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
end

function DataService.AddPlacedItem(player : Player, id : string, tableToInsert)
	local data = PlayerData[player]

	--
	if data then
		if data["PlacedItems"] then
			PlayerData[player]["PlacedItems"][id] = tableToInsert
		else
			warn("[DataService] -> Key (", id, ") does not exist in the data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
end

function DataService.RemovePlacedItem(player : Player, id : string)
	local data = PlayerData[player]

	--
	if data then
		if data["PlacedItems"] then
			PlayerData[player]["PlacedItems"][id] = nil
		else
			warn("[DataService] -> Key (", id, ") does not exist in the data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
end

function DataService.IncrementNumber(player : Player, key : string, amount : number)
	local data = PlayerData[player]
	
	--
	if data then
		if data[key] then
			data[key] += amount
		else
			warn("[DataService] -> Key (", key, ") does not exist in data")
		end
	else
		warn("[DataService] -> Data does not exist for", player.Name)
	end
end

function DataService.ResetData(player : Player)
	local data = PlayerData[player]
	
	--
	if data then
		PlayerData[player] = DefaultData
	end
	
	--
	DataService.SaveData(player)
end

--
function DataService.AutoSave()
	while wait(AUTO_SAVE_INTERVAL) do
		for _, player in ipairs(PlayerService:GetPlayers()) do
			DataService.SaveData(player)
		end
	end
end

--
function DataService.GetData(player : Player)
	return PlayerData[player]
end

return DataService
