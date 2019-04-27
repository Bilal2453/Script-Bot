local discordia = require('discordia')
-- print('\027' .. '[2J')
discordia.extensions()

local fs = require("fs")
local timer = require("timer")
local logger = discordia.Logger(4, "%Y-%m-%d %X")
local date = discordia.Date()

local tokenID = os.getenv("token") or io.open("token.txt", "r"):read()

local client = discordia.Client {
	cacheAllMembers = true,
	syncGuilds = true
}

local modulesTablePath = "./Modules/modulesTable.lua"

local env = setmetatable({require = require, client = client, guild = guild, logger = logger}, {__index = _G})
env.env = env -- Cool, right ?

local modules = loadfile(modulesTablePath, "t", env)()

local lastLoadedModules = {}

local function loadModules()
	for module, path in pairs(modules) do
		if fs.existsSync(path)
		and lastLoadedModules[module] ~= fs.readFileSync(path) then

			local moduleName = tostring(module:sub(1, 1):upper().. module:sub(2) or nil)
			local err
			local su1, loaderFunction
			local su2, returnedGlobal

			-- Remove all listeners for reloading
			-- (if the reload fail without removing these listeners a problem will be waiting)
			if module == "messageHandler" then
				client:removeAllListeners("notBotMessageCreate")
				client:removeAllListeners("ownerMessageCreate")
				client:removeAllListeners("adminMessageCreate")
			elseif module == "messageEventHandler" then
				client:removeAllListeners("eMessageCreate") -- reloads "messageEventHandler"
			end
			_G[module] = nil -- Unload the module before reloading them

			-- re/loading the Modules
			su1, loaderFunction = pcall(loadfile, path, "t", env)
			if su1 then
				su2, returnedGlobal = pcall(loaderFunction)
				if su2 then
					_G[module] = returnedGlobal
				else
					err = returnedGlobal
				end
			else
				err = loaderFunction
			end
			-- Error handling
			if err then
				logger:log(2, "\"".. moduleName.. "\" Module was not loaded.\n"..
				"Error: ".. tostring(err or nil))
				_G[module] = {} -- Fixes a problem: can't index a nil value
			else
				lastLoadedModules[module] = fs.readFileSync(path)
				logger:log(3, "\"".. moduleName.. "\" Module was loaded succesfuly.")
			end

		elseif not fs.existsSync(path) then
			logger:log(1, "No such file: ".. path)
		end
	end
end

client:on('ready', function()
	logger:log(3, 'Logged in as '.. tostring(client.user.username))
	client:setGame({
		name = "Coding Myself..."
	})
	loadModules() -- Loads the Modules
	-- Defining some values to the client
	client._findMember = commands.findMember
	client._badWords = {
		"fuck", "shit", "bitch", "motherfucker", "فك",
		"موثير", "كس", "كسمك", "كسامك", "قحط",
		"قحب", "انبيك", "نيك", "أنيك", "يا كلب",
		"امك", "أمك", "dick", "pussy", "vagena",
		"boobs", "سكس", "sex", "porn", "خرا",
		"زق", "حمار", "زب", "طيز", "طز"
	}
	client._messageHead = "**Beep Boop !!**\n"
	client._runningTime = os.time()

	local Guild = client.guilds:find(function(guild)
		if guild.id == "544595942079463434" then
			return true
		end
	end)
end)

client:on('messageCreate', function(message)
	pcall(loadModules) -- Reloads modules if needs to.
	client:emit("eMessageCreate", message)
	if not tostring(message) then return end

	local args = message.content:split(" ")
	-- Just for some debugging
	if args[1] == "reloadModules" and message.author.id == message.guild.ownerId then
		if args[2] then
			pcall(loadModules)
		end
	end
end)

client:run('Bot '.. tokenID)
