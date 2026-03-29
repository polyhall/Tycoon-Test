-- SERVICES --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- VARIABLES --
local LoadedServices = {}
local LoadedControllers = {}

--
local SharedModule = {}

-- METHODS --
function SharedModule.Load()
	if RunService:IsServer() then
		local ServerStorage = game:GetService("ServerStorage")
		local ServicesFolder = ServerStorage.Services
		
		--
		for _, service in ServicesFolder:GetChildren() do
			LoadedServices[service.Name] = require(service)
		end
	else
		local ControllersFolder = ReplicatedStorage:WaitForChild("Controllers")
		
		--
		for _, controller in ControllersFolder:GetChildren() do
			LoadedControllers[controller.Name] = require(controller)
		end
	end
end

-- --
function SharedModule.GetService(serviceName : string)
	return LoadedServices[serviceName]
end

function SharedModule.GetController(controllerName : string)
	return LoadedControllers[controllerName]
end

-- --
function SharedModule.CallUniversalMethod(methodName : string, ... : any?)
	local list = RunService:IsServer() and LoadedServices or LoadedControllers
	
	--
	for _, child in list do
		if child[methodName] then
			child[methodName](...)
		end
	end
end

-- --
return SharedModule
