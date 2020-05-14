local function eval(message)
	if message.member.id ~= client.owner.id then return end

	local chunk = message.content:split(" ")
	table.remove(chunk, 1)

	chunk = table.concat(chunk, " ")
		:gsub('^``?`?(.-)``?`?$', '%1')
		:gsub('^lua\n?', '')

	local function codeBlock(str) return f('```lua\n%s\n```', str) end

	local evalEnv = setmetatable(table.copy(env), {__index = env})
	evalEnv.message = message
	evalEnv.mesg = message
	evalEnv.commands = env.commands

	evalEnv.channel = message.channel
	evalEnv.chnl = message.channel

	evalEnv.reply = function (tx)
		tx = type(tx) == "table" and #tx == 1 and tx[1] or tx

		if type(tx) ~= "table" then
			message:reply(tx)
			return
		end

		local embed = {
			fields = {},
			color = 0xfaa61a,
		}

		for k, v in pairs(tx) do
			table.insert(embed.fields, {name = k, value = v})
		end

		message:reply{embed = embed}
	end

	local runtimeSucc, exec = load(chunk, 'Eval', 't', evalEnv)
	local succ, returned = pcall(runtimeSucc and runtimeSucc or function()end)

	if not (runtimeSucc and succ) then
		return false, codeBlock(runtimeSucc and returned or exec)
	end

	if returned ~= nil then message:reply(codeBlock(returned)) end
	return true
end

eval = Command('eval', eval)

eval.aliases = {
	"eval",
	"استدع"
}

eval.permissions = {
	"botOwner"
}

return eval
