local function unmute(self)
	if not self.rArgs.message then return false end

	local message = self.rArgs.message
	local person = table.concat(self.args, " ")
	if not person or person == "" then return end

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

unmute = createCommand(unmute, "manageMessages")
unmute.commandNames = {
	"unmute",
	"talk",
	"\216\170\217\131\217\132\217\133"
}

unmute.name = "unmute"
return unmute