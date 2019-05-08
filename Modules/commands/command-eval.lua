local function eval(self)
	local message = self.rArgs.message
	if not message then return end

	if message.author.id ~= message.client.owner.id
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

eval = createCommand(eval, "sendMessages")
eval.commandNames = {
	"eval"
}

eval.name = "eval"
return eval