class Say

  def cmd_say(message)
    reply(message, message.args)
  end

  def cmd_act(message)
    reply(message, "#{1.chr}ACTION #{message.args}#{1.chr}")
  end


end

$modules.push(Say.new)
