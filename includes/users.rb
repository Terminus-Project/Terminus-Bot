
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

User = Struct.new(:connection, :nick, :user, :host, :level, :account)

class Users < Hash

  # Create our users object. These are per-connection, so we're passed
  # our parent.
  def initialize(connection)
    @connection = connection

    # Register events relevant to us.
    $bot.events.create(self, "JOIN",    :add_origin)
    $bot.events.create(self, "352",     :add_352) # WHO reply
    $bot.events.create(self, "PRIVMSG", :add_origin)
    $bot.events.create(self, "NICK",    :change_nick)
    $bot.events.create(self, "QUIT",    :quit)
    $bot.events.create(self, "PART",    :part)
  end

  # User has quit the network. Forget about them.
  def quit(msg)
    return unless msg.connection == @connection

    delete_user(msg.nick)
  end

  # Check if the parting user no longer has any common channels with us.
  # If they don't, forget about them.
  def part(msg)
    msg.connection.channels.each_value do |chan|
      unless chan.get_user(msg.nick) == nil
        return
      end
    end

    delete_user(msg.nick)
  end

  # WHO reply
  def add_352(msg)
    return if msg.connection != @connection
      
    add_user(msg.raw_arr[7], msg.raw_arr[4], msg.raw_arr[5])
  end

  # Add the user in the origin (first word) position of a raw message
  # to our list. Users are here in PRIVMSG and others.
  def add_origin(msg)
    return if msg.connection != @connection

    msg.origin =~ /(.+)!(.+)@(.+)/
      
    add_user($1, $2, $3)
  end

  # Actually add a nick!user@host to our list.
  def add_user(nick, user, host)
    return if has_key? nick

    $log.debug("Users.add_user") { "Adding user #{nick} on #{@connection.name}" }

    self[nick] = User.new(@connection, nick, user, host, 0)
  end

  # Someone changed nicks. Make the necessary updates.
  def change_nick(msg)
    return if msg.connection != @connection
    return unless has_key? msg.nick

    $log.debug("Users.add_user") { "Renaming user #{msg.nick} on #{@connection.name}" }

    # Apparently structs don't let you change values. So just make a
    # new user.
    self[msg.text] = User.new(@connection, msg.text,
                               self[msg.nick].user,
                               self[msg.nick].host,
                               self[msg.nick].level,
                               self[msg.nick].account)

    delete_user(msg.nick)
  end

  # Remove a user by nick.
  def delete_user(nick)
    $log.debug("Users.add_user") { "Removing user #{nick} on #{@connection.name}" }

    delete(nick)
  end

  # Get the level of the user speaking in msg.
  # Used when checking permissions.
  def get_level(msg)
    unless has_key? msg.nick
      add_origin(msg)
    end

    return self[msg.nick].level
  end

  def to_s
    keys.to_s
  end
end

