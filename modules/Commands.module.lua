local COMMANDS_PATH = require './include/constants'.COMMANDS_PATH
local error = aerror
local commands = {}

-- If the commands are already loaded, just reload the Command object
if Commands then
	commands = Commands; Commands = {}
end

local function get(self, property, index)
	local values = {}
	for k, v in pairs(self[property] or {}) do
		if v then
			table.insert(values, k)
		end
	end
	return index and values[index] or values
end

local function set(self, property, index, invert, disable)
	self[property] = self[property] or {}
	self = self[property]

	local function exp(a, b, c)
		if a then
			return b
		else
			return c
		end
	end

	disable = exp(disable, false, nil)
	invert = invert and true or false

	local value = not invert and true or disable
	disable = value == disable and true or disable

	if type(index) == "string" then
		self[index] = value
	elseif type(index) == "table" then
		for k, v in pairs(index) do
			if type(k) == "number" then
				self[v] = value
			else
				self[k] = exp(v, value, disable)
			end
		end
	end
end

-- Unload the Command class if it is already defined
-- This WILL ONLY occur when reloading this module
if discordia.class.classes.Command then discordia.class.classes.Command = nil end
local Command, getters, setters = discordia.class("Command")

--*[[ Defining Class Constructor ]]

function Command:__init(name, callback, aliases, args, perms)
	self.name = error(1, "Command", "string", tostring(name))
	self.arguments = args or {}
	self.aliases = aliases or {}
	self.permissions = perms or {}
	self.callback = callback or function() end
end

--*[[ Defining Class Setters ]]

function setters:name(n)
	self:setName(n)
end

function setters:arguments(v)
	self:setArguments(v or {})
end

function setters:aliases(v)
	self:setAliases(v or {})
end

function setters:permissions(v)
	self:setPermissions(v or {})
end

function setters:callback(v)
	self:setCallback(v or function() end)
end

--*[[ Defining Class Getters ]]

function getters:name()
	return self._name
end

function getters:arguments()
	return self._arguments
end

function getters:aliases(i)
	return get(self, '_aliases', i)
end

function getters:permissions(i)
	return get(self, '_permissions', i)
end

function getters:callback()
	return self._callback
end

--*[[ Defining Members Methods ]]

function Command:setName(n)
	self._name = error(1, "setName", "string", n)
end

-- TODO: Accept only one argument, which will declear all of the flags
-- TODO: or one flag instead of accepting every possible chance.
-- TODO MUST: Simplify the method as much as possible and needed. silly
function Command:setArguments(name, argType, shortflag, fullflag, eatArgs, optional, output)
	self._arguments = self._arguments or {}

	name = error(2, "setArguments", {"string", "table"}, name)

	local function setArgs(args)
		argType = args.type
		shortflag = args.shortflag
		fullflag = args.fullflag
		optional = args.optional
		eatArgs = args.eatArgs
		output = args.output
		name = args.name or ""
	end

	if type(name) == "table" then
		for argName, arg in pairs(name) do
			if type(argName) == "number" then
				self:setArguments(arg)
			elseif type(argName) == "string" and type(arg) == "table" then
				arg.name = arg.name or argName
				self:setArguments(arg)
			elseif type(argName) == "string" and type(arg) ~= "table" then
				setArgs(name)
				break
			end
		end
	end

	if argType == false then
		self._arguments[name] = nil; return
	end

	self._arguments[name] = {
		name = name,
		type = argType,

		shortflag = shortflag,
		fullflag = fullflag,

		eatArgs = eatArgs,
		optional = optional,

		output = output,
	}
end

-- TODO: removeArguments method

function Command:setAliases(a)
	set(self, '_aliases', a)
end

function Command:removeAliases(a)
	set(self, '_aliases', a, true)
end

function Command:setPermissions(p)
	set(self, '_permissions', p, false, true)
end

function Command:removePermissions(p)
	set(self, '_permissions', p, true)
end

function Command:setCallback(c)
	self._callback = error(1, "setCallback", "function", c)
end

-- TODO: register the command object to the auto-update cycle
-- Not sure how though
function Command:register()
	if type(env.Commands) == "table" then
		env.Commands[self.name] = self
	else
		commands[self.name] = self
	end
end

function Command:hasPermissions(member, channel)
	error(1, "hasPermissions", {"Message", "Member"}, member)
	channel = member.channel or channel
	member = member.member or member
	error(2, "hasPermissions", "GuildTextChannel", channel)

	local enums = discordia.enums.permission
	local isEnum = function (e)
		return table.search(table.keys(enums), e)
	end

	local commandsPerms = self._permissions
	local memberPerms = member:getPermissions(channel)
	local specialPerms = {
		["botOwner"]	= client.owner.id == member.id,
		["guildOwner"]	= channel.guild.owner.id == member.id,
	}

	-- This will allow to the owner of the bot to pass any missing permissions
	-- If you don't want this to happen (idk why would you tho) just comment the following line
	if specialPerms.botOwner then return true end

	local function isValid(hasPerm, value)
		if not hasPerm == not value then
			return true
		end
	end

	-- Check if the member does have the default discord permissions (if any)
	for perm, v in pairs(commandsPerms) do
		if isEnum(perm) and not isValid(memberPerms:has(perm), v) then
			return false
		end
	end

	-- Check if the member does have the customized permissions (if any)
	for perm, v in pairs(specialPerms) do
		if commandsPerms[perm] ~= nil and not isValid(v, commandsPerms[perm]) then
			return false
		end
	end

	return true
end

--*[[ Defining The Environment ]]

-- Defining the Command object's constructor to the main environment
env.Command = Command

if env.envLoaders.Commands then
	pcall(env.envLoaders.Commands[1])
end

-- Defining a listener for loading and updating the commands
baseEmitter:_onOnce('initingModulesFinish', function()
	env.envLoaders.Commands = {loadDirec(COMMANDS_PATH, '%.command%.lua$', 'Commands Module', 'Command',
		function(name) Commands[name] = nil end, -- Unloading callback
		function(name, command) Commands[name] = command end -- Loading callback
	)}
end)

return commands
