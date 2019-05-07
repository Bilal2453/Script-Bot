local function shutdown(self)
  if self.rArgs.message.author.id == client.owner.id then
    self.rArgs.message:reply("Shutting Down :confounded: ")
    client:stop()
  end
end

local shutdown = createCommand(shutdown, "administrator")

shutdown.name = "shutdown"
return shutdown