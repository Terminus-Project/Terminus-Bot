class Admin

  def initialize
    @admins = Hash.new()
  end

  def getSpeakerAccessLevel(message)
    getAccessLevel(message.speaker.fullMask)
  end

  def getAccessLevel(hostmask)
    @admins[hostmask].accessLevel rescue 0
  end

  def cmd_level(message)
    if message.msgArr.length == 2
      reply(message, "Current access level: #{ getAccessLevel(message.msgArr[1])}")
    end
  end

  def cmd_login(message)
    if $network.isChannel? message.destination
      reply(message, "You may only use that command in a query.")
    else
      if not message.msgArr.length == 3
        reply(message, "Please give both a user name and password.")
      else
        username = message.msgArr[1]
        password = Digest::MD5.hexdigest(message.msgArr[2])

        $log.info("admin") { "Login attempt from #{message.destination} with user name #{username} and password #{password}" }

        if $config["Core"]["Bot"]["Users"][username].password == password
          reply(message, "Success!")
          @admins[message.speaker.fullMask] = $config["Core"]["Bot"]["Users"][username]
        else
          reply(message, "Failure!")
        end
      end
    end
  end

  def cmd_join(message)
    sendRaw("JOIN #{message.args}")
  end

  def cmd_part(message)
    sendRaw("PART #{message.args}")
  end

  def cmd_quit(message)
    if message.args.empty?
      sendRaw("QUIT :" + $config["Core"]["Bot"]["QuitMessage"])
    else
      sendRaw("QUIT :#{message.args}")
    end
  end


end

$modules.push(Admin.new)
