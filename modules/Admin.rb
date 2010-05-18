class Admin

  def cmd_join(message)
    sendMessage("JOIN #{message.args}")
  end

  def cmd_part(message)
    sendMessage("PART #{message.args}")
  end

  def cmd_quit(message)
    if message.args == ""
      sendMessage("QUIT :Terminus-Bot: TERMINATING")
    else
      sendMessage("QUIT :#{message.args}")
    end
  end


end

$modules.push(Admin.new)
