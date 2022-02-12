local discordia = require 'discordia'
local commandia = require 'commandia'

local configs = require 'configs'

discordia.extensions()

local client = discordia.Client {
	cacheAllMembers = true,
}

commandia.Manager {
  client = client,
  prefix = configs.prefix,
  replyHeader = "**Beep Boop!**\n",
  respondToDMs = true,
}

client:run('Bot ' .. configs.token)
