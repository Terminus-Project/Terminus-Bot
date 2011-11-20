
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

module IRC
  User = Struct.new(:connection, :nick, :user, :host, :level)

  class Users
    def initialize(connection)
      @connection = connection
      @users = Hash.new

      $bot.events.create(self, "JOIN",    :add_origin)
      $bot.events.create(self, "352",     :add_352)
      $bot.events.create(self, "PRIVMSG", :add_origin)
      $bot.events.create(self, "NICK",    :change_nick)
    end

    def add_352(msg)
      return if msg.connection != @connection
        
      add_user(msg.raw_arr[7], msg.raw_arr[4], msg.raw_arr[5])
    end

    def add_origin(msg)
      return if msg.connection != @connection

      msg.origin =~ /(.+)!(.+)@(.+)/
        
      add_user($1, $2, $3)
    end

    def add_user(nick, user, host)
      return if @users.has_key? nick

      $log.debug("Users.add_user") { "Adding user #{nick} on #{@connection.name}" }

      @users[nick] = User.new(@connection, nick, user, host, 0)
    end

    def change_nick(msg)
      return if msg.connection != @connection
      return unless @users.has_key? msg.nick

      $log.debug("Users.add_user") { "Renaming user #{msg.nick} on #{@connection.name}" }

      @users[msg.text] = User.new(@connection, msg.text,
                                  @users[msg.nick].user,
                                  @users[msg.nick].host,
                                  @users[msg.nick].level)

      delete_user(msg.nick)
    end

    def delete_user(nick)
      $log.debug("Users.add_user") { "Removing user #{nick} on #{@connection.name}" }

      @users.delete(nick)
    end

    def get_level(msg)
      unless @users.has_key? msg.nick
        add_origin(msg)
      end

      return @users[msg.nick].level
    end

    def [](nick)
      @users[nick]
    end

    def to_s
      @users.keys.to_s
    end
  end
end

