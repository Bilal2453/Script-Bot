local function isSnowflake(id)
	return type(id) == 'string' and #id >= 17 and #id <= 64 and not id:match('%D')
end
env.isSnowflake = isSnowflake

env.tobool = function(v)
	v = tostring(v:lower())
	return (v == '1' or v == 'on' or v:find('t')) and true or false
end

env.toMember = function(v, g)
	if not v or type(g) ~= "table" then return end

	local mention = v:match('<@%!?(%d+)>')
	local memberID = v:match('%d+')

	local id = mention or memberID
	if not isSnowflake(id) then return end

	return (id and g:getMember(id))
end

env.toChannel = function(v, g)
	local channelMention = v:match('<#(%d+)>')
	local channelID = v:match('%d+')
	local channelName = v:match('[%S%-]+')

	local id = channelMention or channelID

	if id and isSnowflake(id) then
		return client:getChannel(id)
	elseif channelName then
		return g and g.textChannels:find(function(c)
			return c.name == channelName
		end)
	end
end

env.toMessage = function(v, c)
	local guildID, channelID, messageLink = v:match('https://discordapp.com/channels/(%d+)/(%d+)/(%d+)')
	local messageID = v:match('%d+')

	local id = messageLink or messageID
	if not isSnowflake(id) then return end

	if type(c) ~= 'table' then
		if isSnowflake(channelID) then
			c = client:getChannel(channelID)
		elseif isSnowflake(c) then
			c = client:getChannel(c)
		else
			c = env.toChannel(c, client:getGuild(guildID))
		end

		if not c then return end
	end

	return id and c:getMessage(id)
end
