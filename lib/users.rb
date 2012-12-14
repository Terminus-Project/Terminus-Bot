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

module Bot
  User = Struct.new(:connection, :nick, :user, :host, :level, :account)

  class UserManager < Hash

    # Create our users object. These are per-connection, so we're passed
    # our parent.
    def initialize connection
      @connection = connection

      # Register events relevant to us.
      Events.create :JOIN,    self, :add_origin
      Events.create :"352",   self, :add_352 # WHO reply
      Events.create :PRIVMSG, self, :add_origin
      Events.create :NICK,    self, :change_nick
      Events.create :QUIT,    self, :quit
      Events.create :PART,    self, :part
    end

    # User has quit the network. Forget about them.
    def quit msg
      return unless msg.connection == @connection

      delete_user msg.nick_canon
    end

    # Check if the parting user no longer has any common channels with us.
    # If they don't, forget about them.
    def part msg
      msg.connection.channels.each_value do |chan|
        unless chan.get_user(msg.nick_canon) == nil
          return
        end
      end

      delete_user msg.nick_canon
    end

    # WHO reply
    def add_352 msg
      return if msg.connection != @connection

      add_user(msg.connection.canonize(msg.raw_arr[7]), msg.raw_arr[4], msg.raw_arr[5])
    end

    # Add the user in the origin (first word) position of a raw message
    # to our list. Users are here in PRIVMSG and others.
    def add_origin msg
      return if msg.connection != @connection

      msg.origin =~ /(.+)!(.+)@(.+)/

      add_user msg.connection.canonize($1), $2, $3
    end

    # Actually add a nick!user@host to our list.
    def add_user nick, user, host
      return if has_key? nick

      $log.debug("Users.add_user") { "Adding user #{nick} on #{@connection.name}" }

      self[nick] = User.new @connection, nick, user, host, 0
    end

    # Someone changed nicks. Make the necessary updates.
    def change_nick msg
      return if msg.connection != @connection
      return unless has_key? msg.nick_canon

      $log.debug("Users.add_user") { "Renaming user #{msg.nick} on #{@connection.name}" }

      changed_nick_canon = msg.connection.canonize msg.text

      temp = self[msg.nick_canon]

      delete msg.nick_canon

      temp.nick = changed_nick_canon

      self[changed_nick_canon] = temp
    end

    # Remove a user by nick.
    def delete_user nick
      $log.debug("Users.add_user") { "Removing user #{nick} on #{@connection.name}" }

      delete nick
    end

    # Get the level of the user speaking in msg.
    # Used when checking permissions.
    def get_level msg
      add_origin msg unless has_key? msg.nick_canon

      return self[msg.nick_canon].level
    end

    def to_s
      keys.to_s
    end
  end
end
