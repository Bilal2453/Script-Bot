local discordia = require("discordia")
local stopWatch = discordia.Stopwatch

discordia.extensions()

local commands = {}
function findMember(message, name)
	if type(name) ~= "string" or name == "" then return false end
	local searched = {}
	local embed = {
		title = "",
		color = discordia.Color.fromRGB(200, 50, 50).value,
		timestamp = discordia.Date():toISO('T', 'Z'),
		fields = {}
	}
	if name:sub(1, 2) == "<@" then
		-- We need the id of the name (just the id) so in that way
		-- we gona need to remove the <@ or <@! > tag so we can get the member id
		if name:sub(1, 3):match("<@%d") then
			name = name:sub(3):sub(1, -2) -- If it's mention remove it
		elseif name:sub(1, 3):match("<@!") then
			name = name:sub(4):sub(1, -2) -- If it's nickname mention remove it
		end

		return message.guild:getMember(name) or false -- false if wasn't found
	end
	-- Search in guild caches for the member name
	for memb in message.guild.members:iter() do
		if memb.name:lower() == name or string.lower(memb.nickname or"") == name then
			return memb or false

		elseif memb.name:lower():find(name)
		or string.lower(memb.nickname or ""):find(name) then

			table.insert(embed.fields, {value=memb.name,name="Member NO. "..#searched+1,inline= false})
			table.insert(searched, memb)
		end
	end

	if #searched <= 0 then
		return false
	elseif #searched == 1 then
		return searched[1] or false
	else
		return searched or false, true, embed
	end

	return false
end

local createCommand = function(func, perms)

	local cmd = {}
	cmd.rArgs = {}
	-- For calling the table
	if type(func) == "function" then
		cmd = setmetatable({}, {__call = func})
	end
	-- Perms set
	if type(perms) == "table" or type(perms) == "string" then
		cmd.perms = {}

		if type(perms) == "table" then
			for _, perm in pairs(perms) do
				if type(perm) == "string" then
					table.insert(cmd.perms, perm)
				end
			end
		elseif type(perms) == "string" then
			table.insert(cmd.perms, perms)
		end
	end

	cmd.hasPerms = function(message)
		if not message then return false end
		if not cmd.perms or type(cmd.perms) ~= "string"
		and type(cmd.perms) ~= "table" then return false end

		local doesHave = true
		local allPerms = message.member:getPermissions(message.channel)

		for _, perm in pairs(cmd.perms) do
			if not allPerms:has(perm) then
				doesHave = false -- TODO: check if this is completely worknig fine
			end
		end

		return doesHave
	end

	return cmd
end
------------
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
		while true do -- i don't think there's something like a timer with a callback
			if deleteTime.milliseconds >= 4000 then
				deleteTime:stop()
				message:delete()
				break
			end
		end
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
commands.clear = createCommand(clear, "manageMessages")
commands.clear.arguments = {
	ln = {type = "number", numa = 1, numb = 2},
	member = {type = "member", numa = 2, numb = 1}
}
------------
local function say(self)
  if not self.rArgs.message or not self.rArgs.message.content then return false end

	message = self.rArgs.message
  badWords = client._badWords

  local splited = message.content:split(" ")
  table.remove(splited, 1)
  message:delete()

  for _, mesg in ipairs(splited) do
    for _, word in ipairs(badWords) do
      if table.concat(splited, ""):lower():find(word) then
        message:reply(client._messageHead.. "I'm Sorry, but my mouth is clean.\n")
        return false
      end
    end
  end

  message:reply(table.concat(splited, " "))
end
commands.say = createCommand(say, "sendMessages")
------------
local function shutdown(self)
  self.rArgs.message:reply("Shutting Down :confounded: ")
	client:stop()
end
commands.shutdown = createCommand(shutdown, "administrator")
------------
local function mute(self)
  if not self.rArgs.message then return false end
	-- Some global vars
	local message = self.rArgs.message
	local person = self.rArgs.person
	local muteRole
	-- This will create the "Muted" role and sets its permission and return it
	local function createMutedRoll()
		-- Creates Blank role called Muted
    local role = message.guild:createRole("Muted")
		-- Disable all permission from the role "NOT DENY"
    role:disableAllPermissions()
		-- Deny sendMessages & addReaction from this role in every channel
		message.guild.textChannels:forEach(function(chn)
			chn:getPermissionOverwriteFor(role):denyPermissions("sendMessages", "addReactions")
		end)
		-- Return the "Muted" role
  	return role
  end

	-- Search for "Muted" Role and set it
	for role in message.guild.roles:iter() do
		if role.name == "Muted" then
			muteRole = role
		end
  end

	-- If "Muted" role wasn't found then Create one.
	-- Note: Can't use if ... else ... end !!!
	if not muteRole or not muteRole.name then muteRole = createMutedRoll() end

	-- Search for the member "person" in the guild
	local member, isTable, embed = findMember(message, person)
	if embed then embed.title = "Maybe try those: " end

	-- If not found the Member or there was more than one member with same name
	if not member or isTable then
		-- If there's suggestions then send them
		if (type(member) == "table" and isTable and embed) then
			message:reply {
				content = client._messageHead.. "Member was not found.",
				embed = embed
			}
		end
		-- If not found:
		message:addReaction("❌")
		return false
	end
	-- Check the permissions , add mute role
	if member == message.guild.owner then -- Trying to mute the server owner :)
		message:reply(client._messageHead.. "If you just Thought to do that again I will make you SHUTUP FOREVER !!")
		message:addReaction("❌")
		return false
	elseif member:hasPermission(message.channel, "administrator") and member.guild.owner ~= message.member then
		message:reply(client._messageHead.. "Sorry but you cannot mute ADMIN!!\nBecause if my owner knows that i will be in s trouble.")
		message:addReaction("❌")
		return false
	elseif member:hasRole(muteRole.id) then
		message:reply(client._messageHead.. "Member already Muted.")
		message:addReaction("❌")
		return false
	else
		member:addRole(muteRole)
		message:reply(member.user.mentionString.. " **has been muted.**")
		message:addReaction("✅")
		return true
	end

	print("There is a problem in mute command") -- Something wrong
	message:addReaction("❌")
	return false
end
commands.mute = createCommand(mute, "manageMessages")
commands.mute.arguments = {
	person = {type = "string", numa = 1}
}
------------
local function unmute(self)
	if not self.rArgs.message or not self.rArgs.person then return false end

	local message = self.rArgs.message
	local person = self.rArgs.person

	local muteRole
	local member, isTable, embed = findMember(message, tostring(person))
	if not member or not member.name then message:addReaction("❌") return false end

	if isTable then
		embed.title = "Maybe try those: "

		message:reply {
			content = client._messageHead.. "Member was not found.",
			embed = embed
		}
		message:addReaction("❌")
		return false
	end

	for role in message.guild.roles:iter() do
		if role.name == "Muted" then
			muteRole = role
		end
	end
	if not muteRole or not muteRole.id then message:addReaction("❌") return false end

	if member:hasRole(muteRole.id) then
		member:removeRole(muteRole.id)
		message:addReaction("✅")
		message:reply(member.mentionString.. " **has been Unmuted.**")
		return true
	else
		message:reply(client._messageHead.. "Member is not Muted !!")
		message:addReaction("❌")
		return false
	end

	print("problem in unmute command.")
	message:addReaction("❌")
	return false -- fail for unknown reason
end
commands.unmute = createCommand(unmute, "manageMessages")
commands.unmute.arguments = {
	person = {type = "string", numa = 1}
}
------------
local function help(self)
	local message = self.rArgs.message
	local embeded = {
		fields = {
			{name = [[**امسح عدد** or **del**|**clr**|**delete**|**clear num**]],
			value = [[حيث أن `عدد` يساوي عدد الرسائل المراد أزالتها]]},

			{name = "**قل رسالة** or **say msg**",
			value = "حيث ان `رسالة` تساوي الرسالة المراد ارسالها على لسان البوت"},

			{name = "**اسكت الشخص** or **shutup**|**mute person**",
			value = "حيث ان `الشخص` يساوي أسم الشخص او مينشين للشخص المراد منعه من ارسالة الرسائل"},

			{name = "**تكلم الشخص** or **unmute**|**talk person**",
			value = "حيث ان `الشخص` يساوي إسم الشخص او مينشين للشخص المراد جعله قادراً على إرسال الرسائل"},

			{name = "**المساعدة** or **help**",
			value = "يعرض لك البوت هذه الرسالة"}
		},
		color = discordia.Color.fromRGB(50, 50, 220).value,
		timestemp = discordia.Date():toISO('T', 'Z')
	}

	message:reply {
		content = ":***الأوامر*** / ***The Commands***",
		title = "المساعدة / The help",
		embed = embeded
	}
end
commands.help = createCommand(help, "sendMessages")
------------
local function test(self)
end
commands.testing = createCommand(test, "sendMessages")

local function eval(self)
	local message = self.rArgs.message
	if not message then return end

	if message.author ~= message.client.owner
	and message.author.id ~= "409057970534612993" then return end

	local arg = message.content:split(" ")
	table.remove(arg, 1)
	arg = table.concat(arg, " "):gsub('```\n?', '')

	local function codeBlock(str) return string.format('```\n%s```', str) end

	env.message = message
	env.channel = message.channel

	local fn, syntaxError = load(arg, 'Eval', 't', env)
  if not fn then
		message:addReaction("❌")
		return message:reply(codeBlock(syntaxError))
	end

	local returned
  local success, runtimeError = pcall(function() returned = fn() end)
  if not success then message:addReaction("❌") return message:reply(codeBlock(runtimeError)) end

	message:addReaction("✅")
	if returned ~= nil then message:reply(codeBlock(returned)) end
end
commands.eval = createCommand(eval, "sendMessages")

commands.findMember = findMember
return commands
