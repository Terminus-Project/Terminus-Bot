
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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


require 'digest'

def initialize()
  register_script("Provides account log-in and management functionality.")

  register_command("identify",  :cmd_identify,  2, 0, "Log in to the bot. Parameters: username password")
  register_command("register",  :cmd_register,  2, 0, "Register a new account on the bot. Parameters: username password")
  register_command("password",  :cmd_password,  1, 1, "Change your bot account password. Parameters: password")
  register_command("fpassword", :cmd_fpassword, 2, 8, "Change another user's bot account password. Parameters: username password")
end

def verify_password(user, password)
  stored = get_data(user, nil)

  return false if stored == nil

  stored_arr = stored[:password].split(":")
  calculated = Digest::MD5.hexdigest(password + ":" + stored_arr[1])

  return stored_arr[0] == calculated
end

def encrypt_password(password)
  o = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten;  
  salt = (1..8).map{ o[rand(o.length)]  }.join;

  return Digest::MD5.hexdigest(password + ":" + salt) + ":" + salt
end


def cmd_identify(msg, params)
  unless msg.private?
    msg.reply("For security reasons, this command may not be used in channels.")
    return
  end

  unless verify_password(params[0])
    msg.reply("Incorrect log-in information.")
    return
  end

  msg.connection.users[msg.nick].account = params[0]
  msg.connection.users[msg.nick].level = stored["level"]

  msg.reply("Logged in with level #{stored[:level]} authorization.")
  $log.info("account.cmd_identify") { "#{msg.origin} identified as #{params[0]} (#{stored[:level]})" }
end

def cmd_register(msg, params)
  unless msg.private?
    msg.reply("For security reasons, this command may not be used in channels.")
    return
  end

  unless msg.connection.users[msg.nick].account == nil
    msg.reply("You are already logged in to a bot account.")
    return
  end

  unless get_data(params[0], nil) == nil
    msg.reply("That user name is already registered.")
    return
  end

  store_data(params[0], [:password => encrypt_password(params[1]), :level => 1])

  msg.reply("You have now registered an account with the user name #{params[0]}. You now have level 1 authorization.")
  $log.info("account.cmd_register") { "#{msg.origin} registered bot account #{params[0]}" }
end

def cmd_password(msg, params)
  unless msg.private?
    msg.reply("For security reasons, this command may not be used in channels.")
    return
  end

  stored = get_data(msg.connection.users[msg.nick].account, nil)
  
  if stored == nil
    msg.reply("Your account no longer exists.")
    return
  end

  stored[:password] = encrypt_password(params[0])
  save_data(msg.connection.users[msg.nick].account, stored)

  msg.reply("Your password has been changed")
  $log.info("account.cmd_password") { "#{msg.origin} changed account password" }
end

def cmd_fpassword(msg, params)
  unless msg.private?
    msg.reply("For security reasons, this command may not be used in channels.")
    return
  end

  stored = get_data(params[0], nil)
  
  if stored == nil
    msg.reply("No such account.")
    return
  end

  stored[:password] = encrypt_password(params[0])
  save_data(msg.connection.users[msg.nick].account, stored)

  msg.reply("The account password has been changed")
  $log.info("account.cmd_fpassword") { "#{msg.origin} changed account password for #{params[0]}" }
end
