local discordia	= require 'discordia'
local configs		= require './include/configs'
local constants	= require './include/constants'
local loadDirec	= require './include/loader'.loadDirec

local classType = discordia.class.type

local logger = discordia.Logger(4, '%Y-%m-%d %X')
local baseEmitter = discordia.Emitter()
local client = discordia.Client {
	cacheAllMembers = true,
	syncGuilds = true
}

local TOKEN = configs.token or os.getenv('token') or error("Attempt to find the token")
local MODULES_PATH = constants.MODULES_PATH

discordia.extensions()

--*[[ Environment Declaretions ]]


local env =	setmetatable(
	{
		require = require, -- luvit's require
		discordia = discordia,
		client = client,
		logger = logger,
		TOKEN = TOKEN,
		f = string.format,
		constants = constants,
		envLoaders = {},
	}, {__index = _G}
)
env.env = env

local function aerror(n, to, e, v)
	e = type(e) ~= "table" and {e} or e
	local s

	for _, value in ipairs(e) do
		if classType(v) == value then
			s = true; break
		end
	end

	if s then
		return v
	else
		return error(('bad argument #%d to "%s" (%s expected, got %s)'):format(
		n, to, table.concat(e, '|'), classType(v)))
	end
end
env.aerror = aerror

-- This custom method will keep only one listener.
-- Every time it is called will assign the new callback, and remove all old callbacks.
baseEmitter._onOnce = function (self, eName, callback)
	if self:getListenerCount(eName) >= 1 then
		self:removeAllListeners(eName)
	end

	return baseEmitter:on(eName, callback)
end
env.baseEmitter = baseEmitter

function env.assertCmd(success, mesg, obj, reac)
	if type(success) ~= "boolean" then
		reac = obj
		obj = mesg
		mesg = success
		success = false
	end
	obj = aerror(3, 'assertCmd', {'Message','nil'}, obj) or {}

	local isMessage = obj.reply and true
	local send = isMessage and obj.reply or obj.send

	do -- addReaction
		if not isMessage or reac then return end
		if success then
			pcall(obj:addReaction('✅'))
		else
			obj:addReaction('❌')
		end
	end

	if not success then
		if isMessage then
			send(obj, configs.messageHead.. mesg)
		else
			return mesg
		end
	end

	return true
end

-- Ikr... this is kinda dumb but it is best what I can do for now
setfenv(loadDirec, env)
env.loadDirec = loadDirec

--*[[ Events ]]

client:once('ready', function()
	env.envLoaders.Moudles = {loadDirec(MODULES_PATH,
		'%.module%.lua$', nil, 'Module', nil,
		function(name, module) env[name] = module end
	)}

	baseEmitter:emit('initingModulesFinish')
end)

client:on('ready', function()
	logger:log(3, 'Successfully logged in')
	client:setGame{name = 'Coding Myself...'}
end)

client:on('messageCreate', function(message)
	if message.author.bot then return end

	baseEmitter:emit('cMessageCreate', message)
end)

client:run('Bot ' .. TOKEN)
