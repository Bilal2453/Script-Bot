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

local say = createCommand(say, "sendMessages")

say.name = "say"
return say