aliases = {'eval', 'exec', 'استدع', 'استدعاء',}
permissions = 'botOwner'

local sandbox_env = setmetatable({}, {__index = getfenv()})

local function codeBlock(str)
  return '```lua\n' .. tostring(str) .. '\n```'
end

local function reply(...)
  local args_n = select('#', ...)
  local args = {...}
  if args_n > 1 then
    for _, v in ipairs(args) do
      reply(v)
    end
    return
  end
  args = args[1]

  if type(args) ~= 'table' then
    -- TODO: reference message
    sandbox_env.msg:reply(codeBlock(args))
    return
  end

  local embed = {
    fields = {},
    color = 0xfaa61a,
  }
  for k, v in pairs(args) do
    table.insert(embed.fields, {name = k, value = v})
  end
  sandbox_env.msg:reply {embed = embed}
end
sandbox_env.reply = reply

return function(_, msg, _, _, split_args)
  local content = table.concat(split_args, ' ')
    :gsub('^```[^\n]*', '')
    :gsub('```$', '')
    :gsub('^``?(.-)``?$', '%1')

  sandbox_env.message = msg
  sandbox_env.msg = msg
  sandbox_env.channel = msg.channel
  sandbox_env.guild = msg.guild
  sandbox_env.client = msg.client

  local exec, err = load(content, 'eval', 'bt', sandbox_env)
  local success, return_val = pcall(exec and exec or function() end)
  if not (exec and success) then
    return false, codeBlock(exec and return_val or err)
  end

  if return_val ~= nil then
    sandbox_env.reply(return_val)
  end
  return true
end
