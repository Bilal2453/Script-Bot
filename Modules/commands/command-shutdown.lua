local function shutdown(self)
  if self.rArgs.message.author.id == client.owner.id then
    self.rArgs.message:reply("Shutting Down :confounded: ")
    client:stop()
  end
end

shutdown = createCommand(shutdown, "administrator")
shutdown.commandNames = {
  "shutdown"
}

shutdown.name = "shutdown"
return shutdown