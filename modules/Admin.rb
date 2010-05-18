class Admin

  def cmd_join(message)
    sendMessage("JOIN #{message.args}")
  end

  def cmd_part(message)
    sendMessage("PART #{message.args}")
  end

  def cmd_quit(message = "Terminus Bot: Terminating")
    sendMessage("QUIT :#{message}")
  end


end

$modules.push(Admin.new)
