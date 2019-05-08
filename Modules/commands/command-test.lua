local function test(self)
    -- Command for testing purposes
    p(true) 
end

local testing = createCommand(test, "sendMessages")
testing.commandNames = {
    "testing"
}

testing.name = "testing"
return testing