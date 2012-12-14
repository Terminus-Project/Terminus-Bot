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

register "Provides account log-in and management functionality."

command 'identify', 'Log in to the bot. Parameters: username password' do
  query! and argc! 2

  stored = get_data @params[0], nil

  unless verify_password stored, @params[1]
    reply "Incorrect log-in information."
    next
  end

  @connection.users[@msg.nick_canon].account = @params[0]

  level = stored[:level]
  name = @params[0].to_sym

  if Bot::Conf[:admins].has_key? name
    level = Bot::Conf[:admins][name]

    $log.info("account.cmd_identify") { "#{@msg.origin} identifying with override level #{level}" }
  end
    
  @connection.users[@msg.nick_canon].level = level

  reply "Logged in with level #{level} authorization."
  $log.info("account.cmd_identify") { "#{@msg.origin} identified as #{@params[0]} (#{level})" }
end

command 'register', 'Register a new account on the bot. Parameters: username password' do
  query! and argc! 2

  unless @connection.users[@msg.nick_canon].account == nil
    reply "You are already logged in to a bot account."
    next
  end

  unless get_data(@params[0], nil) == nil
    reply "That user name is already registered."
    next
  end

  store_data @params[0], Hash[:password => encrypt_password(@params[1]), :level => 1]

  reply "You have now registered an account with the user name #{@params[0]}. You now have level 1 authorization."
  $log.info("account.cmd_register") { "#{@msg.origin} registered bot account #{@params[0]}" }
end

command 'password',  'Change your bot account password. Parameters: password' do
  query! and level! 1 and argc! 1

  account = @connection.users[@msg.nick_canon].account

  if account.nil?
    reply "You must be logged in to change your password."
    next
  end

  stored = get_data @connection.users[@msg.nick_canon].account, nil
  
  if stored.nil?
    reply "Your account no longer exists."
    next
  end

  stored[:password] = encrypt_password(@params[0])
  store_data @connection.users[@msg.nick_canon].account, stored

  reply "Your password has been changed"
  $log.info("account.cmd_password") { "#{@msg.origin} changed account password" }
end

command 'fpassword', 'Change another user\'s bot account password. Parameters: username password' do
  query! and level! 10 and argc! 2

  stored = get_data @params[0], nil
  
  if stored.nil?
    reply "No such account."
    next
  end

  stored[:password] = encrypt_password @params[0]
  store_data @connection.users[@msg.nick_canon].account, stored

  reply "The account password has been changed"
  $log.info("account.cmd_fpassword") { "#{@msg.origin} changed account password for #{params[0]}" }
end

command 'level', 'Change a user\'s account level. Parameters: username level' do
  level! 10 and argc! 2

  stored = get_data @params[0], nil
  
  if stored.nil?
    reply "No such account."
    next
  end

  level = @params[1].to_i

  if level < 1 or level > 10
    reply "Level must be a whole number from 1 to 10."
    next
  end

  stored[:level] = level

  store_data @params[0], stored

  # if they are logged in, update the live data too

  Connections.each do |name, conn|
    conn.users.each do |nick, user|
      if user.account == @params[0]
        user.level = level
      end
    end
  end

  reply "Authorization level for \02#{@params[0]}\02 changed to \02#{level}\02."
  $log.info("account.cmd_level") { "#{@msg.origin} changed authorization level for #{@params[0]} to #{level}" }
end

command 'account', 'Display information about a user. Parameters: username' do
  level! 2 and argc! 1

  stored = get_data @params[0], nil
  
  if stored.nil?
    reply "No such account."
    next
  end

  reply "\02Account:\02 #{@params[0]} \02Level:\02 #{stored[:level]}"
end

command 'whoami', 'Display your current user information if you are logged in.' do
  u = @connection.users[@msg.nick_canon]

  if u.account.nil?
    reply "You are not logged in."
    next
  end

  reply "\02Account:\02 #{u.account} \02Level:\02 #{u.level}"
end

helpers do
  def verify_password stored, password
    return false if stored == nil

    stored_arr = stored[:password].split ":"
    calculated = Digest::MD5.hexdigest "#{password}:#{stored_arr[1]}"

    stored_arr[0] == calculated
  end

  def encrypt_password password
    o = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten;  
    salt = (1..8).map{ o[rand(o.length)]  }.join;

    "#{Digest::MD5.hexdigest "#{password}:#{salt}"}:#{salt}"
  end
end

