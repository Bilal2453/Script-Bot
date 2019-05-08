local function clear(self)
	if not self.rArgs then return false end
	if not self.rArgs.message then return false end
	if not self.rArgs.ln and not self.rArgs.member then return false end
	-- Some global vars
	local message = self.rArgs.message
	local ln = self.rArgs.ln
	local member = self.rArgs.member

	local channel = message.channel
	local messages = {}
	-- Delete the message that was sent by the member
	local function delMsg()
		local deleteTime = discordia.Stopwatch()
		deleteTime:start()
		-- Wait for it
		timer.setTimeout(4000, function()
			coroutine.wrap(function()
				deleteTime:stop()
				message:delete()
			end)()
		end)
	end
	-- If it wasn't number then try search for someone
  if tonumber(ln) and not member then
		messages = channel:getMessagesBefore(message.id, tonumber(ln))
		ln = tonumber(ln)
	else
		-- If the member wasn't found
		if not member
		or (type(member)=="table" and not member.id) and member[1].id then
			message:reply(client._messageHead.. "Member was not found.")
			return false
		end
		-- Gets the 100 messages before member message
		local tMessages = channel:getMessagesBefore(message.id, 100)
		-- for some unknown reasons sometimes tMessages is nil
		if not tMessages then p("tMessages is empty, message is ".. message) return false end
		-- Check if the message was older than 2 weeks
		-- These are some important vars
		local timeLeng = discordia.Time().fromWeeks(2)
		local currentTime = discordia.Time().fromSeconds(os.time())
		local to = tonumber(ln) or 100
		-- Checking for messages
		for i, mesg in pairs(tMessages:toArray("timestamp")) do
			if mesg.author.id == member.id -- The message was sent by the "member"
			and ((discordia.Date().fromISO(mesg.timestamp):toSeconds())+timeLeng:toSeconds()) > currentTime:toSeconds()
			and i > #tMessages-to then
				table.insert(messages, mesg) -- Insert the message for deleting
			end
		end

		ln = #messages or 0 -- re-define the right value for ln
		if ln == 0 then ln = -5 end -- there is no reason why -5 just any value that's less than zero
  end
	-- If line number was more than 100 or lessThan/equalTo 1 return false
	-- NOTE: Can't convert these if ... elseif ... end statements into one if statement
	local err = false
	do
		if ln > 100 then
			channel:send(client._messageHead.."Sorry but i can't delete more than 100 message due to discord limition.")
			err = true
		elseif ln <= 1 and ln > 0 then
			channel:send(client._messageHead.."Sorry but you can do that, why you need me ?")
			err = true
		elseif ln == -5 then
			channel:send(client._messageHead.."Sorry can't delete messages older than 2 weeks,\nDue to discord limition :pensive:")
			err = true
		end
		-- If there's an error:
		if err then
			message:addReaction("❌")
			delMsg()
			return false
		end
	end
	-- Deletes the messages
	local success = channel:bulkDelete(messages)
	-- See if it was success or not
  if success == true then
		message:addReaction("✅")
	else
		message:addReaction("❌")
		delMsg()
		return false
	end

  delMsg() -- Delete user message anyway

  return true
end

local clear = createCommand(clear, "manageMessages")

clear.arguments = {
	ln = {type = "number", numa = 1, numb = 2},
	member = {type = "member", numa = 2, numb = 1}
}
clear.commandNames = {
	"clear",
	"clr",
	"del",
	"delete",
	"\216\167\217\133\216\179\216\173"
}
clear.name = "clear"

return clear
