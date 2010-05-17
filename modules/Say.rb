class Say

  def cmd_say(message)
    sendMessage("PRIVMSG #{message.origin} :#{message.args}")
  end

  def cmd_act(message)
    sendMessage("PRIVMSG #{message.origin} :#{1.chr}ACTION #{message.args}#{1.chr}")
  end


end

$modules.push(Say.new)
