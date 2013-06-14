
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

  class Channels < CanonizedHash

    # Create a new instance of the Channels class for this connection. This
    # sets up events for all channel-related events on this connection. Event
    # data is then passed to the appropriate {Channel} objects.
    # @param connection [IRCConnection] parent connection
    def initialize connection
      @connection = connection

      Bot::Events.create :JOIN,  self, :on_join
      Bot::Events.create :PART,  self, :on_part
      Bot::Events.create :KICK,  self, :on_kick
      Bot::Events.create :MODE,  self, :on_mode
      Bot::Events.create :"324", self, :on_modes_on_join
      Bot::Events.create :"442", self, :on_not_in_channel

      Bot::Events.create :QUIT,  self, :on_quit

      Bot::Events.create :TOPIC, self, :on_topic
      Bot::Events.create :"332", self, :on_topic_on_join # topic on join

      Bot::Events.create :"352", self, :on_who_reply # who reply
      Bot::Events.create :NAMES, self, :on_names

      Bot::Events.create :NICK,  self, :on_nick

      super(connection)
    end

    # Callback for WHO reply (352 numeric).
    #
    # If the {Channel} for this reply does not yet exist, it is created. Then,
    # a new {ChannelUser} is created and added to the correct {Channel}.
    # Lastly, the modes are parsed out of the WHO reply.
    #
    # @see Channel#join
    # @see Channel#who_modes
    #
    # @param msg [Message] message object triggered the callback
    def on_who_reply msg
      return unless msg.connection == @connection
      channel = msg.raw_arr[3]

      unless has_key? channel
        self[channel] = Channel.new channel, @connection
      end

      self[channel].join(ChannelUser.new(
        self[channel],
        @connection.canonize(msg.raw_arr[7]),
        msg.raw_arr[4],
        msg.raw_arr[5],
        []))

      self[channel].who_modes msg.raw_arr[7], msg.raw_arr[8]
    end

    # Callback for JOIN message.
    #
    # If the {Channel} for this JOIN does not yet exist, it is created. Then,
    # if the joining user is the bot, a MODE and WHO are sent for the channel,
    # just to ensure we have complete information. Lastly, a {ChannelUser} is
    # created and added to the correct {Channel}.
    #
    # @see Channel#join
    #
    # @param msg [Message] message that triggered the callback
    def on_join msg
      return unless msg.connection == @connection

      unless has_key? msg.destination
        self[msg.destination] = Channel.new msg.destination, @connection
        Bot::Flags.add_channel @connection.name.to_s, msg.destination
      end

      if msg.me?
        @connection.raw "MODE #{msg.destination}"
        @connection.raw "WHO #{msg.destination}"
      end

      self[msg.destination].join(ChannelUser.new(
        self[msg.destination],
        msg.nick, msg.user, msg.host, []
      ))
    end

    # Callback for PART message.
    #
    # If the parting user is the bot, the {Channel} is deleted. Otherwise, the
    # user is removed from the {Channel} by calling {Channel#part}.
    #
    # @see Channel#part
    #
    # @param msg [Message] message that triggered the callback
    def on_part msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination

      if msg.me?
        return delete msg.destination
      end

      self[msg.destination].part msg.nick
    end

    # Callback for 442 messsage.
    #
    # If this message is received, the bot has tried to do something in a
    # channel it is not in. Just in case, the channel is removed from the
    # channels list, if it is present.
    #
    # *Generally, this should not be necessary.*
    #
    # @param msg [Message] message that triggered the callback
    def on_not_in_channel msg
      return unless msg.connection == @connection

      channel = msg.raw_arr[3]

      return unless has_key? channel

      delete channel
    end

    # Callback for KICK message.
    #
    # Remove the kicked user form the appropriate {Channel} by calling
    # {Channel#part}.
    #
    # @see Channel#part
    #
    # @param msg [Message] message that triggered the callback
    def on_kick msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination
      # XXX - delete channel if the bot has been kicked

      self[msg.destination].part @connection.canonize msg.raw_arr[3]
    end

    # Callback for MODE message.
    #
    # If this is for a channel, update the modes on the {Channel} by calling
    # {Channel#mode_change}.
    #
    # @see Channel#mode_change
    #
    # @param msg [Message] message that triggered the callback
    def on_mode msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination

      self[msg.destination].mode_change msg.raw_arr[3..-1]
    end

    # Callback for 324 numeric (channel modes shared on JOIN).
    #
    # Update channel modes by calling {Channel#mode_change}.
    #
    # @see Channel#mode_change
    #
    # @param msg [Message] message that triggered the callback
    def on_modes_on_join msg
      return unless msg.connection == @connection
      channel = msg.raw_arr[3]

      return unless has_key? channel

      self[channel].mode_change msg.raw_arr[4..-1]
    end


    # Callback for TOPIC message.
    #
    # Update the stored channel topic by calling {Channel#topic}.
    #
    # @see Channel#topic
    #
    # @param msg [Message] message that triggered the callback
    def on_topic msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination

      self[msg.destination].topic = msg.text
    end

    # Callback for 332 numeric (channel topic shared on JOIN).
    #
    # Update the stored channel topic by calling {Channel#topic}.
    #
    # @see Channel#topic
    #
    # @param msg [Message] message that triggered the callback
    def on_topic_on_join msg
      return unless msg.connection == @connection
      channel = msg.raw_arr[3]

      return unless has_key? channel
      
      match = msg.raw_str.match(/^(\S+ ){4}:(?<topic>.*)$/)

      self[channel].topic = match[:topic]
    end


    # Callback for QUIT message.
    #
    # For each {Channel}, call {Channel#quit}. The {Channel#quit} function will
    # determine whether or not the message applies to it.
    #
    # @see Channel#quit
    #
    # @param msg [Message] message that triggered the callback
    def on_quit msg
      return unless msg.connection == @connection

      # TODO: This is fucko. The Users class needs to hold channel users. We have
      # too much duplicate data.
      each_value do |c|
        c.quit msg
      end
    end

    # Callback for NICK message.
    #
    # For each {Channel}, call {Channel#change_nick}. The {Channel#change_nick}
    # function will determine whether or not the message applies to it.
    #
    # @see Channel#nick
    #
    # @param msg [Message] message that triggered the callback
    def on_nick msg
      return unless msg.connection == @connection

      if msg.me?
        @nick = msg.text
        return
      end

      # TODO: This is fucko. The Users class needs to hold channel users. We have
      # too much duplicate data.
      each_value do |c|
        c.change_nick msg
      end
    end


  end

  class ChannelUser 
    attr_accessor :nick, :user, :host, :modes

    # @param parent [Channel]
    # @param nick [String]
    # @param user [String]
    # @param host [String]
    # @param modes [String]
    def initialize parent, nick, user, host, modes
      @parent = parent
      @nick, @user, @host, @modes = nick, user, host, modes
    end

    # Return the prefix (such as @ for channel operators) for this channel
    # user, if they have one. PREFIX from 005 is used, if available.
    #
    # @return [String] channel user prefix
    def prefix
      @parent.prefixes.each do |prefix, mode|
        return prefix if @modes.include? mode
      end

      ''
    end

  end

  class Channel

    attr_reader :name, :modes, :users, :lists, :prefixes
    attr_accessor :topic

    # Create the channel object. Since all we know when we join is the name,
    # that's all we're going to store here.
    def initialize name, connection
      @name, @connection = name, connection
      @name.freeze

      @topic, @users = "", CanonizedHash.new(connection)
      @modes = {}
      @lists = {} # bans, exempts, etc.

      parse_prefixes
    end

    def name_canon
      @name_canon ||= @connection.canonize(@name)
    end

    # TODO: Move to IRC_Connection.
    def parse_prefixes
      prefixes_arr = @connection.support("PREFIX", "(ov)@+")[1..-1].split(")")

      @prefixes = {}

      prefixes_arr[0].each_char.each_with_index do |c, i|
        @prefixes[prefixes_arr[1][i]] = c
      end
    end

    # Parse mode changes for the channel. The modes are extracted elsewhere
    # and sent here.
    def mode_change(modes)
      $log.debug("Channel.mode_change") { "Changing modes for #{@name}: #{modes}" }

      # 0 = Mode that adds or removes a nick or address to a list. Always has a parameter.
      # 1 = Mode that changes a setting and always has a parameter.
      # 2 = Mode that changes a setting and only has a parameter when set.
      # 3 = Mode that changes a setting and never has a parameter.
      chanmodes = @connection.support("CHANMODES", ",,,,").split(',', 4)

      plus, with_params, who = true, [], false

      modes[0].each_char do |mode|

        case mode

        when "+"
          plus = true
          with_params << mode

        when "-"
          plus = false
          with_params << mode

        else
          if plus

            if chanmodes[3].include? mode
              @modes[mode] = ""
            else
              with_params << mode
            end

          else

            if chanmodes[3].include? mode or chanmodes[2].include? mode
              @modes.delete mode
            else
              with_params << mode
            end

          end

        end
      end

      modes[1..-1].each do |param|
        if with_params.empty?
          $log.warn("Channel.mode_change") { "Mode change parameter with no valid mode: #{param}" }
          next
        end

        key = ""

        until with_params.empty?

          key = with_params.shift

          if key == "+"
            plus = true

          elsif key == "-"
            plus = false

          else
            break

          end

        end

        if key.empty?
          $log.warn("Channel.mode_change") { "Mode change parameter with no valid mode: #{param}" }
          next
        end

        $log.debug("Channel.mode_change") { "#{plus ? "+" : "-"}#{key} => #{param}" }

        if @prefixes.has_value? key
          param = @connection.canonize param

          if plus
            $log.debug("Channel.mode_change") { "Adding #{key} to #{param}" }
            @users[param].modes |= [key]
          else
            $log.debug("Channel.mode_change") { "Removing #{key} from #{param}" }
            @users[param].modes.delete key

            who = true
          end

        elsif chanmodes[0].include? key
          @lists[key] ||= []

          if plus
            @lists[key] |= [param]
          else
            @lists[key].delete param

            @lists.delete key if @lists[key].empty?
          end

        else
          if plus
            @modes[key] = param
          else
            @modes.delete key
          end
        end

      end

      @connection.raw("WHO #{@name}") if who and not @connection.caps.include? :multi_prefix
    end

    def op? nick
      return false unless @users.has_key? nick

      return true if @users[nick].modes.include? "q"
      return true if @users[nick].modes.include? "a"
      return true if @users[nick].modes.include? "o"

      # This is here for one IRCD that supports it. It shouldn't conflict with
      # anything else though.
      @users[nick].modes.include? "y"
    end

    def half_op? nick
      return false unless @users.has_key? nick

      return true if op? nick

      @users[nick].modes.include? "h"
    end

    def voice? nick
      return false unless @users.has_key? nick

      return true if op? nick or half_op? nick

      @users[nick].modes.include? "v"
    end

    # Add a user to our channel's user list.
    def join user
      $log.debug("Channel.join") { "#{user.nick} joined #{@name}" }

      @users[@connection.canonize user.nick] = user
    end

    # Remove a user from our channel's user list.
    def part nick
      return nil unless @users.include? nick

      $log.debug("Channel.part") { "#{nick} parted #{@name}" }

      @users.delete nick
    end

    # Remove a user from our channel's user list.
    def quit msg
      return nil unless @users.include? msg.nick

      $log.debug("Channel.quit") { "#{msg.nick} quit #{@name}" }

      Events.dispatch :QUIT_CHANNEL, msg, {:channel => self}

      @users.delete msg.nick
    end

    # Retrieve the channel user object for the named user, or return nil
    # if none exists.
    def get_user nick
      @users.fetch nick, nil
    end

    # Someone changed nicks. Make the necessary updates.
    def change_nick msg
      return unless @users.has_key? msg.nick

      $log.debug("Channel.change_nick") { "Renaming user #{msg.nick} on #{@name}" }

      # Apparently structs don't let you change values. So just make a
      # new user.
      changed_user = ChannelUser.new self,
                                     msg.text,
                                     @users[msg.nick].user,
                                     @users[msg.nick].host,
                                     @users[msg.nick].modes

      @users.delete msg.nick
      @users[msg.text] = changed_user
    end

    def who_modes nick, info
      $log.debug("Channel.who_modes") { "#{nick} => #{info}" }

      info.each_char do |c|

        if @prefixes.has_key? c

          $log.debug("Channel.who_modes") { "#{c} => #{@prefixes[c]}" }

          next unless @users.has_key? nick

          @users[nick].modes |= [@prefixes[c]]

        end

      end
    end
  end
end

# vim: set tabstop=2 expandtab:
