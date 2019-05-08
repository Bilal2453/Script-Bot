local function mute(self)
  if not self.rArgs.message then return false end
	-- Some global vars
	local message = self.rArgs.message
	local person = table.concat(self.args, " ")
	if not person or person == "" then return end
	
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

mute = createCommand(mute, "manageMessages")
mute.commandNames = {
	"mute",
	"shutup",
	"\216\167\216\179\217\131\216\170"
}

mute.name = "mute"
return mute