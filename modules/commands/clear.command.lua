local timer = require 'timer'

local setTimeout = timer.setTimeout
local sleep = timer.sleep

local FETCHING_LIMIT				= 100
local BULKDELETE_LIMIT			= 100
-- local BULKDELETE_TIME_LIMIT	= 1209600 -- 1209600s = 14 day
local COMMANDS_LIMIT				= 200
local DELETE_AFTER = 4000

local function mergeTables(t1, ...)
	local newTable = t1

	for _, tb in ipairs{...} do
		for _, v in ipairs(tb) do
			table.insert(newTable, v)
		end
	end

	return newTable
end

local function fetch(methodn, id, limit, chnl, fn, mesgs)
	if limit > COMMANDS_LIMIT then
		return false, 1 -- 1 == command's limit reached out
	end

	local index
	local a = limit <= FETCHING_LIMIT and limit or FETCHING_LIMIT
	mesgs = mesgs or {}

	local method
	if methodn:find('after') then
		method = chnl.getMessagesAfter
		index = 1
	else
		method = chnl.getMessagesBefore
	end

	local suc, err = method(chnl, id, a)
	if not suc then return suc, err end

	local sortedMessages = suc:toArray('createdAt', fn)

	mergeTables(mesgs, sortedMessages)
	id = sortedMessages[index or #sortedMessages].id

	if limit <= FETCHING_LIMIT then
		return mesgs
	else
		return fetch(methodn, id, limit - FETCHING_LIMIT, chnl, fn, mesgs)
	end
end

local filterMsgs = function(filter)
	return function(m)
		if not filter then return true end

		for k, v in pairs(filter) do
			return k == 'author' and m[k].id == v or m[k] == v
		end
	end
end

local function fetchBefore(id, limit, c, filter, mesgs)
	return fetch('before', id, limit, c, filterMsgs(filter), mesgs)
end

local function fetchAfter(id, limit, c, filter, mesgs)
	return fetch('after', id, limit, c, filterMsgs(filter), mesgs)
end

local function fetchBetween(msg1, msg2, c, filter)
	if msg2.id == msg1.id then
		return nil, "The *to* Message has to be a different message"
	elseif msg2.id > msg1.id then
		msg1, msg2 = msg2, msg1
	end

	local mesgs = {msg1}
	local fetchedMsgs, err, sortedMsgs, f
	local i, index = 1, msg1

	filter = filterMsgs(filter)
	local nfilter = function (msg)
		if not (msg.id >= msg2.id and msg.id < msg1.id) then
			f = true; return
		else
			return filter(msg)
		end
	end

	while i < (COMMANDS_LIMIT * 2 / FETCHING_LIMIT) do
		fetchedMsgs, err = c:getMessagesBefore(index, FETCHING_LIMIT)
		if not fetchedMsgs then return false, err end

		sortedMsgs = fetchedMsgs:toArray('id', nfilter)
		mergeTables(mesgs, sortedMsgs)

		-- Using two toArray ? That's just stupid
		-- TODO: solve this.. probably make my own filter
		index = fetchedMsgs:toArray('id')[1]

		i = i + 1
		if f then break end
	end

	return mesgs
end

local function bulkDeleteAll(msgs, channel)
	local msgsSize = #msgs
	local succ, err

	if msgsSize > BULKDELETE_LIMIT then
		local requiredLoops = math.ceil(msgsSize / BULKDELETE_LIMIT)
		local currentSet = 0

		for _ = 1, requiredLoops do
			succ, err = channel:bulkDelete(table.slice(msgs, currentSet, currentSet + BULKDELETE_LIMIT))
			if not succ then return nil, err end

			sleep(2000)
			currentSet = currentSet + BULKDELETE_LIMIT
		end
	else
		succ, err = channel:bulkDelete(msgs)
		if not succ then return nil, err end
	end

	return true
end

-- TODO: Handle bulk-delete 14 day limit
local function callback(message, flags, args)
	local channel = message.channel

	local is1Member = toMember(args[1], message.guild)
	local is2Member = toMember(args[2], message.guild)
	local targetedMember = flags.targetedMember or is1Member or is2Member

	local amount = flags.amount or (not is1Member and tonumber(args[1])) or (not is2Member and tonumber(args[2])) or BULKDELETE_LIMIT

	local beforeMessage = flags.before
	local afterMessage = flags.after

	local filter = targetedMember and {member = targetedMember}

	if amount > COMMANDS_LIMIT then
		return false, f('Invalid value for "amount" : Must be equal to or less than %d', COMMANDS_LIMIT)
	end

	local function delMsg()
		message:addReaction('✅')
		setTimeout(DELETE_AFTER,
			coroutine.wrap(message.delete), message)
	end

	local mesgs, err
	if beforeMessage and not afterMessage then
		mesgs, err = fetchBefore(beforeMessage.id, amount, channel, filter)
	elseif afterMessage and not beforeMessage then
		mesgs, err = fetchAfter(afterMessage.id, amount, channel, filter)
	elseif afterMessage and beforeMessage then
		mesgs, err = fetchBetween(beforeMessage, afterMessage, channel, filter)
	else
		mesgs, err = fetchBefore(message.id, amount, channel, filter)
	end

	if not mesgs then return nil, err end

	mesgs, err = bulkDeleteAll(mesgs, channel)
	if not mesgs then return nil, err end

	pcall(delMsg)
end

local command = Command('clear', callback)

command:setArguments{
	targetedMember = {
		type = "member",
		shortflag = 'm',
		fullflag = "member"
	},
	amount = {
		type = "number",
		shortflag = 'a',
		fullflag = "amount"
	},
	after = {
		type = "message",
		shortflag = 'r',
		fullflag = "after"
	},
	before = {
		type = "message",
		shortflag = 'b',
		fullflag = "before"
	}
}

command:setAliases{
	"clear", "del"
}

command:setPermissions{
	"manageMessages"
}

return command
