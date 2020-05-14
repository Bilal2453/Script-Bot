return Command('say', (function(message, _, args)
	message:delete()
	message:reply(table.concat(args, ' '))
end), "say", nil, {
	"botOwner"
})
