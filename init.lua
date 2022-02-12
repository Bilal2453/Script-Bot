local fs = require 'fs'
local exists, write = fs.existsSync, fs.writeFileSync

local discordia = require 'discordia'
local commandia = require 'commandia'
local configs

do -- load configs
  if exists './configs.lua' then
    configs = require 'configs'
  else
    configs = {}
    write('./configs.lua', 'return {}')
  end
end

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
