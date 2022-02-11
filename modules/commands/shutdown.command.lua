local function callback(message)
	logger:log(2, "Shutting Down Client...")	
	message:reply "Shutting Down :confounded: "
	client:stop()
	os.exit(1)
end

return Command('shutdown', callback, {"shutdown", "sh"}, nil, "botOwner")
