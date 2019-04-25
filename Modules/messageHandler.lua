local discordia = require('discordia')
discordia.extensions()

local function callCommand(command, message, ...)
  if type(command) ~= "function" and type(command) ~= "table" then return false end
  if not commands then return false end

  local args = {...}
  local s, e
  local object = {message = message}

  if command.arguments then
    for argName, argTable in pairs(command.arguments) do
		for i, v in pairs(type(args[1]) == "table" and args[1] or args) do
			if i == argTable.numa or i == argTable.numb then
				if argTable.type == "number" then
					object[argName] = tonumber(v)
				elseif argTable.type == "string" then
					object[argName] = tostring(v)
				elseif argTable.type == "member" then
					object[argName] = client._findMember(message, v)
				end
			end
		end
	end
  end
  
  command.rArgs = object

  if command.hasPerms and command.hasPerms(message) then
    s, e = pcall(command, message, args)
  else
    message:reply(client._messageHead.. "You don't have Permission to do that!!")
    s = true -- It's not an error
  end

  if not s then
    logger:log(1, e or "e is nil!!")
  end
end

-- Welcome Handling
client:on("notBotMessageCreate", function(message, args)
  if message.author.bot then return false end

  if not message.content:find("say") and not message.content:find("\217\130\217\132") then
    local words = {
      "hi",
      "hello",
      "hey",
      "\216\167\217\132\216\179\217\132\216\167\217\133\032\216\185\217\132\217\138\217\131\217\133",
      "\217\133\216\177\216\173\216\168\216\167"
    }

    for _, n in pairs(words) do
      if message.content:lower() == n:lower() then
        message.channel:send("اهلاً وسهلاً ويا مرحباً بالحلو ".. message.author.mentionString)
      end
    end
  end
end)

-- Owner Commands Handling
-- client:on("ownerMessageCreate", function(message, args)
--   if args[1] == "shutdown" then
--     commands.shutdown(message)
--   end
-- end)

-- Commands Handling
client:on("notBotMessageCreate", function(message, args)
  -- Say command
  if args[1] == "\217\130\217\132" or args[1] == "say" then
    callCommand(commands.say, message)
  elseif args[1] == "\216\167\217\133\216\179\216\173"
  or args[1] == "del" or args[1] == "delete"
  or args[1] == "clr" or args[1] == "clear" or args[1] == "cls" then
    table.remove(args, 1)
    callCommand(commands.clear, message, args)

  elseif args[1] == "shutup" or args[1] == "mute"
  or args[1] == "\216\167\216\179\217\131\216\170" then

    table.remove(args, 1)
    callCommand(commands.mute, message, table.concat(args, " "))

  elseif args[1] == "unmute"
  or args[1] == "\216\170\217\131\217\132\217\133" or args[1] == "talk" then

    table.remove(args, 1)
    callCommand(commands.unmute, message, table.concat(args, " "))
  elseif args[1] == "help" or args[1] == "\216\167\217\132\217\133\216\179\216\167\216\185\216\175\216\169" then
    callCommand(commands.help, message)
  elseif args[1] == "test" then
	table.remove(args, 1)
    callCommand(commands.testing, message, args)
  end
end)
