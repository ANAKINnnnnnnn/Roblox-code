local ValuablesModule = {}

--Module responsible of the hitbox creation
local hitboxCreator = require(game.ServerScriptService.GameLogic.ValuablesSpawnPickUp:WaitForChild("HitBox"))

--Event used 
local replicatedStorage = game:GetService("ReplicatedStorage")
local newHitboxClaim = replicatedStorage:WaitForChild("NewHitbox")

--Function to reset all the part, make them invinsible, unCollidable and remove hitboxes 
--Mostly use in the start of the game
--Takes a folder in argument where the valuables are supposed to be stored
function ValuablesModule.resetPart(folder)
    --Check if the valuable folder is valid
	if not folder or not folder:IsA("Folder") then
		warn("Invalid folder provided to resetPart")
		return
	end

    --Loop in to the folder to select each part 
	for index, part in pairs(folder:GetChildren()) do
        --Loop through all descendants of each tool to make sure that only the BasePart is modified and not directly the tool
		for _, obj in pairs(part:GetDescendants()) do
			if obj:IsA("BasePart") then
                --Makes sure to destroy all hitboxes before the game start or if the game needs to be restarted
				if obj.Name == "Hitbox" then
					obj:Destroy()
				end
				obj.Transparency = 1
				obj.CanTouch = false
				obj.Anchored = true
				obj.CanCollide = false
			end
		end
	end	
end


--Function used to randomly enable a number (index) of tools and creat new hitboxes for each of them, main logic of the module
function ValuablesModule.randomPartsSpawn(index, folder)

    --Check for the folder
	if not folder or not folder:IsA("Folder") then
		warn("Invalid folder provided to randomSpawnPart")
		return
	end

    --Make a list of all the tools in the folder
	local tools = {}
	for _, part in pairs(folder:GetChildren()) do
		if part:IsA("Tool") then
			table.insert(tools, part)
		end
	end

    --Check if the folder actually contains tools
	if #tools == 0 then
		warn("No tools found in folder")
		return
	end

    --Safety check to make sure that we are not enabling more tools than we currently have 
	local numToEnable = math.min(index, #tools)

    --Setup a list of a tool to shuffle it 
	local indice = {}
	for i = 1, #tools  do
		indice[i] = i
	end

    --Shuffle the tools and pick a random one (loops bacward from the last index to the second)
	for i = #indice, 2, -1 do
		local j = math.random(i)
        --Swaps the value of i and j to randomise the order
		indice[i], indice[j] = indice[j], indice[i]
	end

    --Creat a list to keep a track on the tools that are unable
	local enableTools = {}
    --Same thing for hitboxes
	local createdHitboxes = {}
    --Loops through the number of tools to unable
	for i = 1, numToEnable do
		local toolIndex = indice[i]
		local tool = tools[toolIndex]
        --The tool become visible but still cannot have anny interactions
		for _, obj in pairs(tool:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Transparency = 0
				obj.CanTouch = false
			end
		end
        --Intermission between each spawn (optional)
		task.wait(0.1)
        --Creat an hitbox for each visible tool with the hitboxCreator 
		for _, obj in pairs(tool:GetDescendants()) do
			if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj.Name ~= "Hitbox" then
				local hb = hitboxCreator.createHitbox(obj)
                --Insert the new hitbox in the list of hitbox created
				table.insert(createdHitboxes, hb)
			end
		end
		
        --Special check for BasePart (optional can be used for extra logic later on)
		local basePart = tool:FindFirstChild("BasePart")
		if basePart and basePart:IsA("BasePart") then
			local hitbox = hitboxCreator.createHitbox(basePart)
			table.insert(createdHitboxes, hitbox)
			print("Created hitbox for BasePart in tool: " .. tool.Name)
		end
        --Insert the new Tool into the enableTools list
		table.insert(enableTools, tools[toolIndex])
	end

    --Return both list of unable tools and hitboxes created
	return enableTools, createdHitboxes
end

--Function made to disable only one part, make a part invisible to create the ilusion that the player actually picked up the part
function ValuablesModule.disableableSinglePart(tool)
    --Check for the tool
	if not tool or not tool:IsA("Tool") then
		warn("Invalid Tool")
		return
	end
	
	--Loop through the children of the tool to find the BasePart 
	for _, obj in pairs(tool:GetChildren()) do
		if obj:IsA("BasePart")  then
            --Destroy the hitbox and make the part invisible
			if obj.Name == "Hitbox" then
				obj:Destroy()	
			else
				obj.Transparency = 1
				obj.CanTouch = false	
				obj.CanCollide = false
			end
		end
		
	end

end

--Function made to spawn random part across the map
function ValuablesModule.randomSpawnWood(index, folder)
	
    --Check for the folder
	if not folder or not folder:IsA("Folder") then
		warn("Invalid folder provided to randomSpawnWood")
		return
	end
	
    --Specific variables (map size and water height settings)
	local halfSize = 2044 / 2
	local waterY = -16 
	local childrens = folder:GetChildren()
	
	--Spawn random parts
	for i = 1, index  do
        --Take a random part
		local randomPart = childrens[math.random(1, #childrens)]
        --Clone it and setup random position
		local clone = randomPart:Clone()
		clone.Parent = workspace.Valuables:WaitForChild("DriftWood")
		local handle = clone:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
            --Set the position to a random number between the limit of the map and the water level
			handle.Position = Vector3.new(
				math.random(-halfSize, halfSize),
				waterY,
				math.random(-halfSize, halfSize)
			)
		else
			warn("Cloned tool has no valid Handle:", clone.Name)
		end
		
        --Intermission (optional)
		task.wait(0.01)
	end
end


--Function made to unable a single part, likely used after an interaction with another part 
--Simulate respawning
function ValuablesModule.randomSingleSpawn(folder, currentPart)
    --Intemission (optional)
	task.wait(0.5)
    --Check for the folder
	if not folder or not folder:IsA("Folder") then
		warn("Invalid folder provided to randomSingleSpawn")
		return
	end

    --Create a list to count the tools
	local tools = {}
	for _, part in pairs(folder:GetChildren()) do
		local hitbox = part:FindFirstChild("Hitbox")
		if part:IsA("Tool") and part ~= currentPart and not hitbox then
			table.insert(tools, part)
		end
	end

    --Ensure that the number of tools is higher than 0 
	if #tools == 0 then
		warn("No tools found in folder")
		return
	end

    --Take a random tool in the list
	local randomIndex = math.random(#tools)
	local chosenTool = tools[randomIndex]

	--Reset the tool visuals
	for _, obj in pairs(chosenTool:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "Hitbox" then
			obj.Transparency = 1
			obj.CanTouch = false
		end
	end

    --Loop through the descendant of the chosen tool and apply the modifications 
	for _, obj in pairs(chosenTool:GetDescendants()) do
		local tool = obj:FindFirstAncestorOfClass("Tool")
        --Check if the object is already enable with the hitbox
		if obj:IsA("BasePart") and obj.Name ~= "Hitbox" then
			local hasHitbox = false
			for _, siblings in pairs(tool:GetChildren()) do
				if siblings:IsA("BasePart") and siblings.Name == "Hitbox" then
					hasHitbox = true
					break
				end
			end
            --If not the object is set to be visible
			if not hasHitbox then
				obj.Transparency = 0
				obj.CanTouch = false
			end
		end
	end
    --Creation of the hitbox
	local createdHitboxes = {}
	task.wait(0.1)
	for _, obj in pairs(chosenTool:GetDescendants()) do
		if (obj:IsA("Part") or obj:IsA("MeshPart")) and obj.Name ~= "Hitbox" then
			local hb = hitboxCreator.createHitbox(obj)
			table.insert(createdHitboxes, hb)
		end
	end

    --Same returns has before
	return chosenTool, createdHitboxes
end

return ValuablesModule
