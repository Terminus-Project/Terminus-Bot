#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# TODO: Use less terrible password encryption. Add code to convert password on
#       login.

require 'digest'

def initialize
  register_script "Provides account log-in and management functionality."

  register_command "identify",  :cmd_identify,  2,  0,  nil, "Log in to the bot. Parameters: username password"
  register_command "register",  :cmd_register,  2,  0,  nil, "Register a new account on the bot. Parameters: username password"
  register_command "password",  :cmd_password,  1,  1,  nil, "Change your bot account password. Parameters: password"
  register_command "fpassword", :cmd_fpassword, 2, 10,  nil, "Change another user's bot account password. Parameters: username password"
  register_command "level",     :cmd_level,     2, 10, nil, "Change a user's account level. Parameters: username level"
  register_command "account",   :cmd_account,   1,  5, nil, "Display information about a user. Parameters: username"
  register_command "whoami",    :cmd_whoami,    0,  0, nil, "Display your current user information if you are logged in."
end

def verify_password stored, password
  return false if stored == nil

  stored_arr = stored[:password].split ":"
  calculated = Digest::MD5.hexdigest "#{password}:#{stored_arr[1]}"

  return stored_arr[0] == calculated
end

def encrypt_password password
  o = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten;  
  salt = (1..8).map{ o[rand(o.length)]  }.join;

  return "#{Digest::MD5.hexdigest "#{password}:#{salt}"}:#{salt}"
end


def cmd_identify msg, params
  unless msg.private?
    msg.reply "For security reasons, this command may not be used in channels."
    return
  end

  stored = get_data params[0], nil

  unless verify_password stored, params[1]
    msg.reply "Incorrect log-in information."
    return
  end

  msg.connection.users[msg.nick_canon].account = params[0]

  level = stored[:level]
  name = params[0].to_sym

  if Bot::Conf[:admins].has_key? name
    level = Bot::Conf[:admins][name]

    $log.info("account.cmd_identify") { "#{msg.origin} identifying with override level #{level}" }
  end
    
  msg.connection.users[msg.nick_canon].level = level

  msg.reply "Logged in with level #{level} authorization."
  $log.info("account.cmd_identify") { "#{msg.origin} identified as #{params[0]} (#{level})" }
end

def cmd_register msg, params
  unless msg.private?
    msg.reply "For security reasons, this command may not be used in channels."
    return
  end

  unless msg.connection.users[msg.nick_canon].account == nil
    msg.reply "You are already logged in to a bot account."
    return
  end

  unless get_data(params[0], nil) == nil
    msg.reply "That user name is already registered."
    return
  end

  store_data params[0], Hash[:password => encrypt_password(params[1]), :level => 1]

  msg.reply "You have now registered an account with the user name #{params[0]}. You now have level 1 authorization."
  $log.info("account.cmd_register") { "#{msg.origin} registered bot account #{params[0]}" }
end

def cmd_password msg, params
  unless msg.private?
    msg.reply "For security reasons, this command may not be used in channels."
    return
  end

  stored = get_data msg.connection.users[msg.nick_canon].account, nil
  
  if stored == nil
    msg.reply "Your account no longer exists."
    return
  end

  stored[:password] = encrypt_password(params[0])
  store_data msg.connection.users[msg.nick_canon].account, stored

  msg.reply "Your password has been changed"
  $log.info("account.cmd_password") { "#{msg.origin} changed account password" }
end

def cmd_fpassword msg, params
  unless msg.private?
    msg.reply "For security reasons, this command may not be used in channels."
    return
  end

  stored = get_data params[0], nil
  
  if stored == nil
    msg.reply "No such account."
    return
  end

  stored[:password] = encrypt_password params[0]
  store_data msg.connection.users[msg.nick_canon].account, stored

  msg.reply "The account password has been changed"
  $log.info("account.cmd_fpassword") { "#{msg.origin} changed account password for #{params[0]}" }
end

def cmd_level msg, params
  stored = get_data params[0], nil
  
  if stored == nil
    msg.reply "No such account."
    return
  end

  level = params[1].to_i

  if level < 1 or level > 10
    msg.reply "Level must be a whole number from 1 to 10."
    return
  end

  stored[:level] = level

  store_data params[0], stored

  # if they are logged in, update the live data too

  Connections.each do |name, conn|
    conn.users.each do |nick, user|
      if user.account == params[0]
        user.level = level
      end
    end
  end

  msg.reply "Authorization level for \02#{params[0]}\02 changed to \02#{level}\02."
  $log.info("account.cmd_level") { "#{msg.origin} changed authorization level for #{params[0]} to #{level}" }
end

def cmd_account msg, params
  stored = get_data params[0], nil
  
  if stored == nil
    msg.reply "No such account."
    return
  end

  msg.reply "\02Account:\02 #{params[0]} \02Level:\02 #{stored[:level]}"
end

def cmd_whoami msg, params
  if msg.connection.users[msg.nick_canon].account == nil
    msg.reply "You are not logged in."
    return
  end

  u = msg.connection.users[msg.nick_canon]
  msg.reply "\02Account:\02 #{u.account} \02Level:\02 #{u.level}"
end

