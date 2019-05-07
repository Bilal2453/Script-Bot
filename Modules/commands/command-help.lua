local function help(self)
	local message = self.rArgs.message
	local embeded = {
		fields = {
			{name = [[**امسح عدد** or **del**|**clr**|**delete**|**clear num**]],
			value = [[حيث أن `عدد` يساوي عدد الرسائل المراد أزالتها]]},

			{name = "**قل رسالة** or **say msg**",
			value = "حيث ان `رسالة` تساوي الرسالة المراد ارسالها على لسان البوت"},

			{name = "**اسكت الشخص** or **shutup**|**mute person**",
			value = "حيث ان `الشخص` يساوي أسم الشخص او مينشين للشخص المراد منعه من ارسالة الرسائل"},

			{name = "**تكلم الشخص** or **unmute**|**talk person**",
			value = "حيث ان `الشخص` يساوي إسم الشخص او مينشين للشخص المراد جعله قادراً على إرسال الرسائل"},

			{name = "**المساعدة** or **help**",
			value = "يعرض لك البوت هذه الرسالة"}
		},
		color = discordia.Color.fromRGB(50, 50, 220).value,
		timestemp = discordia.Date():toISO('T', 'Z')
	}

	message:reply {
		content = ":***الأوامر*** / ***The Commands***",
		title = "المساعدة / The help",
		embed = embeded
	}
end

local help = createCommand(help, "sendMessages")

help.name = "help"
return help