#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

  class UserManager < CanonizedHash

    # Set up user-related event handlers.
    #
    # @param connection [IRCConnection] parent connection
    def initialize connection
      @connection = connection

      # Register events relevant to us.
      Events.create :JOIN,    self, :add_origin
      Events.create :"352",   self, :add_352 # WHO reply
      Events.create :PRIVMSG, self, :add_origin
      Events.create :NICK,    self, :change_nick
      Events.create :QUIT,    self, :quit
      Events.create :PART,    self, :part

      super(connection)
    end

    # Callback for QUIT message.
    #
    # Forget everything about the user that has quit.
    #
    # @param msg [Message] message that triggered the callback
    def quit msg
      return unless msg.connection == @connection

      delete_user msg.nick
    end

    # Callback for PART message.
    #
    # If the parting user no longer has any common channels, forget about them.
    #
    # @param msg [Message] message that triggered the callback
    def part msg
      still_visible = msg.connection.channels.values.any? do |chan|
        chan.get_user(msg.nick) != nil
      end

      return if still_visible

      delete_user msg.nick
    end

    # Callback for WHO message.
    #
    # Call {UserManager#add_user} with received data in case this is a the
    # first time we have seen this user.
    #
    # @param msg [Message] message that triggered the callback
    def add_352 msg
      return if msg.connection != @connection

      add_user(msg.raw_arr[7], msg.raw_arr[4], msg.raw_arr[5])
    end

    # Add the user info from the origin portion of a message to our user list.
    #
    # @param msg [Message] message from which to use the origin
    def add_origin msg
      return if msg.connection != @connection

      # XXX - this whole function feels awful

      msg.origin =~ /(.+)!(.+)@(.+)/

      add_user $1, $2, $3
    end

    # Add a user to our user list.
    #
    # @param nick [String] nick of user to add
    # @param user [String] user name of user to add
    # @param host [String] host name of user to add
    def add_user nick, user, host
      return if key? nick

      $log.debug("Users.add_user") { "Adding user #{nick} on #{@connection.name}" }

      self[nick] = User.new @connection, nick, user, host, 0
    end

    # Callback for NICK message.
    #
    # This will update the nick info in our user list.
    #
    # @param msg [Message] message that triggered the callback
    def change_nick msg
      return if msg.connection != @connection
      return unless key? msg.nick

      $log.debug("Users.add_user") { "Renaming user #{msg.nick} on #{@connection.name}" }

      temp = self[msg.nick]

      delete msg.nick

      temp.nick = msg.text

      self[msg.text] = temp
    end

    # Forget the user with the given nick.
    #
    # @param nick [String] nick of user to forget
    def delete_user nick
      $log.debug("Users.add_user") { "Removing user #{nick} on #{@connection.name}" }

      delete nick
    end

    # Check a speaker's account level. Typically used when checking permissions
    # for commands. Adds the speaker to the user list if they do not already
    # exist.
    #
    # @see Command#level!
    #
    # @param msg [Message] message for which to check the speaker's level
    # @return [Integer] account level of speaker
    def get_level msg
      add_origin msg unless key? msg.nick

      return self[msg.nick].level
    end

    # @return [String] list of known nicks
    def to_s
      keys.to_s
    end
  end
end
# vim: set tabstop=2 expandtab:
