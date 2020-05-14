local pathJoin = require "pathjoin".pathJoin
local c = {}


c.MODULES_PATH		= "./modules/"
c.CONFIGS_JSON		= "./configs.json"
c.COMMANDS_PATH	= pathJoin(c.MODULES_PATH, "commands/")


return c
