local setTimeout = require 'timer'.setTimeout

local function callback(message, flags, args)
	local channel = message.channel
	local bulkDelLimit = 100
	local bulkDelTimeLimit = 1209600 -- 1209600s = 14 day
	local fetchMessagesLimit = 100
	local commandLimit = 500
	local deleteAfter = 4000
	local loopLimit = math.ceil(commandLimit / bulkDelLimit)
	local is1Member = toMember(args[1], message.guild)
	local is2Member = toMember(args[2], message.guild)

	targetedMember = flags.targetedMember or is1Member or is2Member
	amount = flags.amount or (not is1Member and tonumber(args[1])) or (not is2Member and tonumber(args[2])) or bulkDelLimit

	if amount > commandLimit then
		return false, f('Invalid value for "amount" : Must be equal to or less than %d', commandLimit)
	end

	local function delMsg()
		message:addReaction('✅')
		setTimeout(deleteAfter,
			coroutine.wrap(message.delete), message)
	end

	local function getMessages()
		local lastMesg = message.id
		local rMessages = {}
		local loopStart = 1
		local whileI = 0 -- if something goes wrong inside of the while loop, and it didn't stop, this counter will force it to stop
		local neededLoops = math.ceil(amount / bulkDelLimit)
		local remaining = amount > bulkDelLimit and (amount % bulkDelLimit) or 0
		local isFinish = function(i) return i > neededLoops and (#rMessages[i] >= remaining) or (#rMessages[i] >= bulkDelLimit or #rMessages[i] >= amount) or (#rMessages >= loopLimit) end

		for i = loopStart, neededLoops + (remaining > 0 and 1 or 0) do
			rMessages[i] = rMessages[i] or {}

			while true do
				whileI = whileI + 1
				if isFinish(i) or whileI >= loopLimit then break end

				local fMesgs = channel:getMessagesBefore(lastMesg, fetchMessagesLimit):toArray('createdAt')
				table.reverse(fMesgs)

				for _, mesg in ipairs(fMesgs) do
					if isFinish(i) then break end

					if not targetedMember or targetedMember.id == mesg.member.id then
						table.insert(rMessages[i], mesg)
					end
				end

				lastMesg = fMesgs[100]
			end
		end

		return rMessages
	end

	local baseErrMesg = "Error Deleting Message(s) : "
	for _, q in ipairs(getMessages()) do
		if #q == 1 and q[1] and q[1].id then
			local mesg, err = channel:getMessage(q[1].id)
			if not mesg then return false, baseErrMesg.. err:gsub('.-%s*:(.+)', '%1') end

			mesg, err = mesg:delete()
			if not mesg then return false, baseErrMesg.. err:gsub('.-%s*:(.+)', '%1') end
		elseif #q > 1 then
			if (discordia.Date():toSeconds() - q[#q].createdAt) >= bulkDelTimeLimit then
				return false, baseErrMesg.. f('Cannot delete messages older than %d day.',
					bulkDelTimeLimit / 60 / 60 / 24)
			end

			local success, err = channel:bulkDelete(q)
			if not success then return false, baseErrMesg.. err:gsub('.-%s*:(.+)', '%1') end
		end
	end

	pcall(delMsg)
end

local command = Command('clear', callback)

command:setArguments{
	targetedMember = {
		type = "member",
		shortflag = "m",
		fullflag = 'member'
	},
	amount = {
		type = "number",
		shortflag = 'a',
		fullflag = 'amount'
	}
}

command:setAliases{
	"clear", "del"
}

command:setPermissions{
	"guildOwner"
}

return command
