local discordia = require("discordia")
local fs = require("fs")
local stopWatch = discordia.Stopwatch

discordia.extensions()


function findMember(message, name)
	if type(name) ~= "string" or name == "" then return false end
	local searched = {}
	local embed = {
		title = "",
		color = discordia.Color.fromRGB(200, 50, 50).value,
		timestamp = discordia.Date():toISO('T', 'Z'),
		fields = {}
	}

	if name:sub(1, 2) == "<@" then
		name = name:gsub("%p*", "") -- get the ID only
		return message.guild:getMember(name) or false -- false if wasn't found
	end
	-- Search in guild caches for the member name
	for memb in message.guild.members:iter() do
		if memb.name:lower() == name or string.lower(memb.nickname or"") == name then
			return memb or false

		elseif memb.name:lower():find(name)
		or string.lower(memb.nickname or""):find(name) then

			table.insert(embed.fields, {value=memb.name,name="Member NO. "..#searched+1,inline= false})
			table.insert(searched, memb)
		end
	end

	if #searched <= 0 then
		return false
	elseif #searched == 1 then
		return searched[1] or false
	else
		return searched or false, true, embed
	end

	return false
end

local createCommand = function(func, perms)

	local cmd = {}
	cmd.rArgs = {}

	-- For calling the table
	if type(func) == "function" then
		cmd = setmetatable({}, {__call = func})
	end

	-- Perms set
	if type(perms) == "table" or type(perms) == "string" then
		cmd.perms = {}

		if type(perms) == "table" then
			for _, perm in pairs(perms) do
				if type(perm) == "string" then
					table.insert(cmd.perms, perm)
				end
			end
		elseif type(perms) == "string" then
			table.insert(cmd.perms, perms)
		end
	end

	cmd.hasPerms = function(message)
		if not message then return false end
		if not cmd.perms or type(cmd.perms) ~= "string"
		and type(cmd.perms) ~= "table" then return false end

		local doesHave = true
		local allPerms = message.member:getPermissions(message.channel)

		for _, perm in pairs(cmd.perms) do
			if not allPerms:has(perm) then
				doesHave = false
			end
		end

		return doesHave
	end

	return cmd
end

local commands = {}
local commandsDirec = "./Modules/commands/"

local commandsEnv = setmetatable({require = env.require, client = client, findMember = findMember, createCommand = createCommand, stopWatch = stopWatch, discordia = discordia}, {__index = _G})
commandsEnv.env = env
commandsEnv.timer = env.timer

-- Loading Commands
local lastLoaded = {}
local function loadCommands()
	local files = {}
	local tFiles = fs.readdirSync(commandsDirec)

	for _, name in pairs(tFiles) do
		if name:sub(1, 8) == "command-" then
			if lastLoaded[name] ~= fs.readFileSync(commandsDirec.. name) then
				table.insert(files, commandsDirec.. name)
				lastLoaded[name] = fs.readFileSync(commandsDirec.. name)
			end
		end
	end

	for _, path in pairs(files) do
		local success, loadFunc = pcall(loadfile, path, "t", commandsEnv)
		if not success then
			logger.log(2, path.. " was not loaded\n".. "Error: ".. tostring(loadFunc))
			return
		end

		local success, cmd = pcall(loadFunc)
		if not success then
			logger.log(2, path.. " was not loaded\n Error: ".. tostring(cmd))
			return
		end

		commands[type(cmd) == "table" and cmd.name or 0] = cmd or nil
	end
end
-- Loads the commands for the first time.
loadCommands()

-- Try to reload commands on every message sent.
client:emit("messageCreate", function()
	loadCommands()
end)
return commands
