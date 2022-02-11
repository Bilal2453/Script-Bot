local gmatch = require('rex').gmatch
local PREFIX = require('./include/configs').prefix

local function getFlag(n, c)
	for _, v in pairs(c.arguments) do
		if table.search(v, n) then
			return v
		end
	end
end

local function split(str)
	local args = {}

	for i in gmatch(str, [[(?|"(.+?)"|'(.+?)'|(\S+))]]) do
		table.insert(args, i)
	end

	return args
end

local function argsParser(str, command)
	local splitMesg = split(str)
	table.remove(splitMesg, 1)

	local args = {}
	local flags = {}

	local function valid(i, q)
		return type(splitMesg[i + q]) == 'string' and
			not splitMesg[i + q]:match('^(%-%-?)')
	end

	local lastIndexedFlagArg = 0
	local fm, name, flag

	for i, v in ipairs(splitMesg) do
		fm, name = v:match('^(%-%-?)(%S+)')

		if fm then
			flag = getFlag(name, command)

			if not flag then
				return false, f('Unknown flag "%s"', fm.. name)
			end

			flags[flag.name] = {}

			for q = 1, (flag.eatArgs == -1 and #splitMesg) or flag.eatArgs or 1 do
				if valid(i, q) then
					table.insert(flags[flag.name], splitMesg[i + q]:lower())
					lastIndexedFlagArg = i + q
				else
					break
				end
			end

		elseif i > lastIndexedFlagArg then
			table.insert(args, v)
		end
	end

	return {flags = flags, args = args}
end

local function callCommand(command, message)
	local splitMesg = split(message.content)
	table.remove(splitMesg, 1)

	local commandsArgs, err = argsParser(message.content, command)

	-- One of the inputed arguments can't be found
	if not commandsArgs and err then
		assertCmd(err, message)
		return
	end

	local flags = commandsArgs.flags
	local args = commandsArgs.args

	-- Set a new value for every entry in a table
	-- to the return of the passed callback
	local function fi(t, c)
		local success, e
		for k, v in pairs(t) do
			success, e = pcall(c, v)
			if not success then return false, e end
			t[k] = e
		end
	end

	-- Process and convert the arguments to their assigned types
	local flag, sucs, errmsg
	for flagname, flagargs in pairs(commandsArgs.flags) do
		flag = getFlag(flagname, command)

		-- Call the 'output' callback if any
		-- meant to format the data before the conversion
		if type(flag.output) == 'function' then
			sucs, errmsg = pcall(flag.output, flagargs)
			if sucs then
				flagargs = errmsg
			else
				logger:log(1, 'Error in "%s" Flag\'s output handler : %s', flagname, errmsg)
			end
		end

		if flag.type == 'number' then
			fi(flagargs, tonumber)
		elseif flag.type == 'boolean' then
			fi(flagargs, tobool)
		elseif flag.type == 'member' then
			fi(flagargs, function(v) return toMember(v, message.guild) end)
		elseif flag.type == 'channel' then
			fi(flagargs, function(v) return toChannel(v, message.guild) end)
		elseif flag.type == 'message' then
			fi(flagargs, function(v) return toMessage(v, message.channel) end)
		elseif type(flag.type) == 'function' then
			-- Call the custom conversion callback if any
			sucs, errmsg = fi(flagargs, flag.type)
			if not sucs then
				logger:log(1, 'Error in "%s" Flag\'s type handler : %s', flagname, errmsg)
			end
		end

		flags[flagname] = #flagargs <= 1 and flagargs[1] or flagargs
	end

	local s, e, m
	if command:hasPermissions(message) then
		s, e, m = pcall(command.callback, message, flags, args, splitMesg)
	else
		assertCmd("You don't have enough permissions to execute this command", message)
		return true
	end

	if not s then
		logger:log(1, e or
			f('Unknown error while executing "%s" command', command.name))
		return
	end

	if e then
		assertCmd(true, m, message)
	elseif e ~= nil or not e and m then
		assertCmd(m, message)
	end

	return true
end

local splitMesg
return baseEmitter:_onOnce('cMessageCreate', function(message)
	splitMesg = split(message.content)

	for _, command in pairs(env.Commands or {}) do
		if #command.aliases < 1 then
			if splitMesg[1] == PREFIX .. command.name then
				callCommand(command, message)
				break
			end
		else
			for _, name in pairs(command.aliases or {}) do
				if splitMesg[1] == PREFIX .. name then
					callCommand(command, message)
					break
				end
			end
		end
	end
end)
