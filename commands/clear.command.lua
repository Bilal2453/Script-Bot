aliases = {'clear', 'purge', 'امسح', 'مسح',}
permissions = 'manageMessages'
arguments = {
  targetedMember = {
		type = "member",
		shortflag = 'm',
		fullflag = "member"
	},
	limit = {
		type = "number",
		shortflag = 'l',
		fullflag = "limit"
	},
	after = {
		type = "message",
		shortflag = 'a',
		fullflag = "after"
	},
	before = {
		type = "message",
		shortflag = 'b',
		fullflag = "before"
	}
}

local FETCH_LIMIT				= 100
local BULKDELETE_LIMIT	= 100
local COMMANDS_LIMIT		= 200
local DELETE_AFTER      = 4000
-- local BULKDELETE_TIME_LIMIT	= 14 * 24 * 60 * 60



