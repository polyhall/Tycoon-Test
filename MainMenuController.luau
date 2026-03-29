-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- VARIABLES --
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- --
local GuiManager = require(ModulesFolder:WaitForChild("GUIManager"))

--
local MainMenuGUI : ScreenGui = GuiManager.GetGui("MainMenu")
local MainFrame : Frame = MainMenuGUI:WaitForChild("MainFrame")
local ContentFrame : Frame = MainFrame:WaitForChild("Content")
local ButtonListFrame : Frame = ContentFrame:WaitForChild("ButtonList")
local NewGameConfirmationFrame : Frame = MainMenuGUI:WaitForChild("NewGameConfirmation")

--
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")

--
local NewGameRemote = RemotesFolder:WaitForChild("NewGame")
local LoadGameRemote = RemotesFolder:WaitForChild("LoadGame")

--
local SharedModule = require(ReplicatedStorage:WaitForChild("SharedModule"))
local AudioModule = require(ModulesFolder:WaitForChild("AudioManager"))

--
local ButtonConnections = {}

-- --
local MainMenuController = {}

-- METHODS --
function MainMenuController.OnStart()
	MainMenuController.ButtonList()
	MainMenuController.ControlNewGameConfirmation()
end

-- --
function MainMenuController.NewGame()
	MainMenuController.ShowNewGameConfirmation()
end

function MainMenuController.LoadGame()
	local attempt : string = LoadGameRemote:InvokeServer()
	
	--
	if attempt ~= "Success" then
		-- do error stuff here

		AudioModule.PlaySoundLocal("UIError")
		return
	end
	
	--
	MainMenuController.Dispose()
end

-- --
function MainMenuController.ButtonList()
	for _, button in ButtonListFrame:GetChildren() do
		if button:IsA("TextButton") then
			
			ButtonConnections[button.Name .. "Activated"] = button.Activated:Connect(function()
				-- add disabled button features
				AudioModule.PlaySoundLocal("UIClick")
				
				--
				if button.Name == "NewGame" then
					MainMenuController.NewGame()
				end
				
				--
				if button.Name == "LoadGame" then
					MainMenuController.LoadGame()
				end
			end)
			
			ButtonConnections[button.Name .. "Hovered"] = button.MouseEnter:Connect(function()
				AudioModule.PlaySoundLocal("UIHover")
			end)
			
		end
	end
end

function MainMenuController.ShowNewGameConfirmation()
	NewGameConfirmationFrame.Visible = true
	MainFrame.Visible = false
end

function MainMenuController.HideNewGameConfirmation()
	NewGameConfirmationFrame.Visible = false
	MainFrame.Visible = true
end


function MainMenuController.ControlNewGameConfirmation()
	local YesOption : TextButton = NewGameConfirmationFrame.Content.ButtonList.Yes
	local NoOption : TextButton = NewGameConfirmationFrame.Content.ButtonList.No
	
	--
	YesOption.Activated:Connect(function()
		AudioModule.PlaySoundLocal("UIClick")
		
		--
		local attempt : string = NewGameRemote:InvokeServer()

		--
		if attempt ~= "Success" then
			-- do error stuff here

			AudioModule.PlaySoundLocal("UIError")
			return
		end

		--
		MainMenuController.Dispose()
	end)
	
	--
	NoOption.Activated:Connect(function()
		AudioModule.PlaySoundLocal("UIClick")
		
		--
		MainMenuController.HideNewGameConfirmation()
	end)
end

-- --
function MainMenuController.Dispose()
	SharedModule.GetController("BuildMenuController").ShowBottomBar()
	
	MainMenuGUI.Enabled = false
	table.clear(ButtonConnections)
end

-- --
return MainMenuController
