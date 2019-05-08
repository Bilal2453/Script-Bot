local discordia = require('discordia')
discordia.extensions()

local function callCommand(command, message, ...)
  if type(command) ~= "function" and type(command) ~= "table" then return end
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
  command.args  = args[1]

  if command.hasPerms and command.hasPerms(message) then
    s, e = pcall(command, message, args)
  else
    message:reply(client._messageHead.. "You don't have Permissions to do that!!")
    s = true -- It's not an error
  end

  if not s then
    logger:log(1, e or "e is nil!!")
  end
end

local function commandsSpliter(message)
  if not message or not message.content then return false end

  local cmds = message.content:split(" ")
  for i, v in pairs(cmds) do
    cmds[i] = v:lower() or v
  end
  return cmds
end

client:on("eMessageCreate", function(message)
  local args = commandsSpliter(message)
  if message.author.bot then return end

  for _, command in pairs(commands) do
    for _, name in pairs(command.commandNames or  {}) do
      if args[1] == client._perfix.. name then
        table.remove(args, 1)
        callCommand(command, message, args)
        break
      end
    end
  end
end)

-- Welcome Handling
--[[
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
]]