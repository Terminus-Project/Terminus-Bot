#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#

def hasLevel(message, minLevel)
  getSpeakerAccessLevel(message) >= minLevel
end

def checkPermission(message, minLevel)
  unless hasLevel(message, minLevel)
    reply(message, "You do not have permission to do that.", true)

    $log.info('admin') { "Nick #{message.speaker.nick} tried to use #{message.msgArr[0]} with insufficient access level." }

    return false
  end
  $log.info('admin') { "Nick #{message.speaker.nick} used #{message.msgArr[0]}" }

  return true
end

def getSpeakerAccessLevel(message)
  getAccessLevel(message.speaker.partialMask)
end

def getAccessLevel(hostmask)
  $bot.admins[hostmask].accessLevel rescue 0
end

def cmd_level(message)
  if message.msgArr.length == 2
    reply(message, "Current access level: #{ getAccessLevel(message.msgArr[1])}")
  end
end

def cmd_login(message)
  unless message.private?
    reply(message, "You may only use that command in a query.", true)
  else
    if not message.msgArr.length == 3
      reply(message, "Please give both a user name and password.")
    else
      username = message.msgArr[1]

      stored = $bot.config["Users"][username].password.split(":")

      password = Digest::MD5.hexdigest("#{message.msgArr[2]}#{stored[1]}")

      passwordOK = $bot.config["Users"][username].password == "#{password}:#{stored[1]}"

      $log.info("admin") { "Login attempt from #{message.speaker.nick} with user name #{username} and password #{password}" }

      if passwordOK
        reply(message, "Success!")
        $bot.admins[message.speaker.partialMask] = $bot.config["Users"][username]
      else
        reply(message, "Failure!")
      end
    end
  end
end

def cmd_eval(message)
  begin
    result = eval(message.args)
  rescue => e
    result = "There was an error processing your request: #{e}"
  end
  reply(message, result, true) if checkPermission(message, 9)
end

def cmd_schedule(message)
  reply(message, $scheduler.schedule.join(", "), true) if checkPermission(message, 9)
end

def cmd_raw(message)
  sendRaw(message.args) if checkPermission(message, 9)
end

def cmd_join(message)
  return true if not checkPermission(message, 5)
  sendRaw("JOIN #{message.args}")
  $bot.config["Channels"] << message.args unless $bot.config["Channels"].include? message.args
end

def cmd_part(message)
  return true if not checkPermission(message, 5)
  sendRaw("PART #{message.args}")
  $bot.config["Channels"].delete(message.args) if $bot.config["Channels"].include? message.args
end

def cmd_adminadd(message)
  return true if not checkPermission(message, 9)

  if message.msgArr.length != 4
    reply(message, "Usage: adminadd #{UNDERLINE}username#{NORMAL} #{UNDERLINE}password#{NORMAL} #{UNDERLINE}level#{NORMAL}")
    return true
  end  

  salt = (0...5).map{65.+(rand(25)).chr}.join

  adminPassword = "#{Digest::MD5.hexdigest("#{message.msgArr[2]}#{salt}")}:#{salt}"
  adminUserObj = AdminUser.new(message.msgArr[1], adminPassword, message.msgArr[3])
  $bot.config["Users"][message.msgArr[1]] = adminUserObj
  reply(message, "User #{BOLD}#{message.msgArr[1]}#{NORMAL} added with admin level #{BOLD}#{message.msgArr[3]}#{NORMAL}.")
end

def cmd_quit(message)
  if checkPermission(message, 9)
    if message.args.empty?
      sendRaw("QUIT :" + $bot.config["QuitMessage"])
    else
      sendRaw("QUIT :#{message.args}")
    end
  end
end
