local fs = require "fs"
local decode = require "json".decode

local CONFIGS_PATH = require "./constants".CONFIGS_JSON
local DEFAULT_CONFIGS = {
	['token']			= nil,
	['prefix']			= '>',
	['messageHead']	= '**Beep Boop !!**\n',
}

local readfile, exists = fs.readFileSync, fs.existsSync


local data, errmsg = readfile(CONFIGS_PATH)

if not data then
	if not exists(CONFIGS_PATH) then return DEFAULT_CONFIGS end

	error(("Attempt to read configs file : %s"):format(errmsg))
	return DEFAULT_CONFIGS
end

local parsedJsonData, _, err = decode(data)
if err then
	error(("Attempt to parse configs file : %s"):format(err))
	return DEFAULT_CONFIGS
end

for k, v in pairs(DEFAULT_CONFIGS) do
	if not parsedJsonData[k] then
		parsedJsonData[k] = v
	end
end

return parsedJsonData
