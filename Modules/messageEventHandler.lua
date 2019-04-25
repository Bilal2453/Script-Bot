local function commandsSpliter(message)
  if not message or not message.content then return false end

  local cmds = message.content:split(" ")
  for i, v in pairs(cmds) do
    cmds[i] = v:lower() or v
  end
  return cmds
end
-- NOTE: I really don't know what i want to do with this module
-- i don't know if i need this anymore or this is just a trash.
client:on("eMessageCreate", function(message)
	if message then
		if not message.author.bot then
			client:emit("notBotMessageCreate", message, commandsSpliter(message))
		else
			client:emit("botMessageCreate", message, commandsSpliter(message))
		end

		if message.author.id == message.guild.ownerId then
			client:emit("ownerMessageCreate", message, commandsSpliter(message))
		end

		if message.member:hasPermission("administrator")
		and not message.author.bot then
			client:emit("adminMessageCreate", message, commandsSpliter(message))
		end
	end
end)
