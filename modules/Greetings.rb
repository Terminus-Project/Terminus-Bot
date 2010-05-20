 class Greetings
   
def bot_onMessageReceived(message)
     if message.message =~ /^Hello #{$config["Core"]["Bot"]["Nickname"]}$/
      reply(message, "Hello, #{message.speaker.nick}! It is great to have you again!")
        elsif message.message =~ /^Hey #{$config["Core"]["Bot"]["Nickname"]}$/
	  reply(message, "Hello, #{message.speaker.nick}! Hey is for horses.")
	elsif message.message =~ /^Sup #{$config["Core"]["Bot"]["Nickname"]}$/
	  reply(message, "Sup #{message.speaker.nick}? Hello, I think you mean.")
	elsif message.message =~ /^Hi #{$config["Core"]["Bot"]["Nickname"]}$/
	  reply(message, "Hi, #{message.speaker.nick}.")
    end
   end
 end
$modules.push(Greetings.new)