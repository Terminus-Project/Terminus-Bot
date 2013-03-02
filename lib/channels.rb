
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

  class Channels < Hash

    def initialize connection
      @connection = connection

      Bot::Events.create :JOIN,  self, :on_join
      Bot::Events.create :PART,  self, :on_part
      Bot::Events.create :KICK,  self, :on_kick
      Bot::Events.create :MODE,  self, :on_mode
      Bot::Events.create :"324", self, :on_modes_on_join

      Bot::Events.create :QUIT,  self, :on_quit

      Bot::Events.create :TOPIC, self, :on_topic
      Bot::Events.create :"332", self, :on_topic_on_join # topic on join

      Bot::Events.create :"352", self, :on_who_reply # who reply
      Bot::Events.create :NAMES, self, :on_names

      Bot::Events.create :NICK,  self, :on_nick
    end


    def on_who_reply msg
      return unless msg.connection == @connection
      canon_name = @connection.canonize msg.raw_arr[3]

      unless has_key? canon_name
        self[canon_name] = Channel.new canon_name, @connection
      end

      self[canon_name].join(ChannelUser.new(
        self[canon_name],
        @connection.canonize(msg.raw_arr[7]),
        msg.raw_arr[4],
        msg.raw_arr[5],
        []))

      self[canon_name].who_modes msg.raw_arr[7], msg.raw_arr[8]
    end


    def on_join msg
      return unless msg.connection == @connection

      unless has_key? msg.destination_canon
        self[msg.destination_canon] = Channel.new msg.destination_canon, @connection
        Bot::Flags.add_channel @connection.name.to_s, msg.destination_canon
      end

      if msg.me?
        @connection.raw "MODE #{msg.destination}"
        @connection.raw "WHO #{msg.destination}"
      end

      self[msg.destination_canon].join(ChannelUser.new(
        self[msg.destination_canon],
        msg.nick_canon, msg.user, msg.host, []
      ))
    end

    def on_part msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      if msg.me?
        return delete msg.destination_canon
      end

      self[msg.destination_canon].part msg.nick_canon
    end

    def on_kick msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      self[msg.destination_canon].part @connection.canonize msg.raw_arr[3]
    end

    def on_mode msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      self[msg.destination_canon].mode_change msg.raw_arr[3..-1]
    end

    def on_modes_on_join msg
      return unless msg.connection == @connection
      canon_name = @connection.canonize msg.raw_arr[3]

      return unless has_key? canon_name

      self[canon_name].mode_change msg.raw_arr[4..-1]
    end


    def on_topic msg
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      self[msg.destination_canon].topic msg.text
    end

    def on_topic_on_join msg
      return unless msg.connection == @connection
      canon_name = @connection.canonize msg.raw_arr[3]

      return unless has_key? canon_name

      self[canon_name].topic msg.text
    end


    def on_quit msg
      return unless msg.connection == @connection

      # TODO: This is fucko. The Users class needs to hold channel users. We have
      # too much duplicate data.
      each_value do |c|
        c.part msg.nick
      end
    end

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

  # TODO: Track channel users in the user objects rather than here.
  class ChannelUser 
    attr_accessor :nick, :user, :host, :modes

    def initialize parent, nick, user, host, modes
      @parent = parent
      @nick, @user, @host, @modes = nick, user, host, modes
    end

    def prefix
      @parent.prefixes.each do |prefix, mode|
        return prefix if @modes.include? mode
      end

      ''
    end

  end

  class Channel

    attr_reader :name, :topic, :modes, :users, :lists, :prefixes

    # Create the channel object. Since all we know when we join is the name,
    # that's all we're going to store here.
    def initialize name, connection
      @name, @connection = name, connection
      @name.freeze

      @topic, @users = "", {}
      @modes = {}
      @lists = {} # bans, exempts, etc.

      parse_prefixes
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
      nick = @connection.canonize nick

      return false unless @users.has_key? nick

      return true if @users[nick].modes.include? "q"
      return true if @users[nick].modes.include? "a"
      return true if @users[nick].modes.include? "o"

      # This is here for one IRCD that supports it. It shouldn't conflict with
      # anything else though.
      @users[nick].modes.include? "y"
    end

    def half_op? nick
      nick = @connection.canonize nick

      return false unless @users.has_key? nick

      return true if op? nick

      @users[nick].modes.include? "h"
    end

    def voice? nick
      nick = @connection.canonize nick

      return false unless @users.has_key? nick

      return true if op? nick or half_op? nick

      @users[nick].modes.include? "v"
    end

    # Store the topic.
    def topic str
      @topic = str
    end

    # Add a user to our channel's user list.
    def join user
      $log.debug("Channel.join") { "#{user.nick} joined #{@name}" }

      @users[@connection.canonize user.nick] = user
    end

    # Remove a user from our channel's user list.
    def part nick
      $log.debug("Channel.part") { "#{nick} parted #{@name}" }

      @users.delete @connection.canonize(nick)
    end

    # Retrieve the channel user object for the named user, or return nil
    # if none exists.
    def get_user nick
      nick = @connection.canonize nick

      @users.has_key?(nick) ? @users[nick] : nil
    end

    # Someone changed nicks. Make the necessary updates.
    def change_nick msg
      return unless @users.has_key? msg.nick_canon

      $log.debug("Channel.change_nick") { "Renaming user #{msg.nick} on #{@name}" }

      changed_nick_canon = msg.connection.canonize msg.text

      # Apparently structs don't let you change values. So just make a
      # new user.
      changed_user = ChannelUser.new self,
                                     changed_nick_canon,
                                     @users[msg.nick_canon].user,
                                     @users[msg.nick_canon].host,
                                     @users[msg.nick_canon].modes

      @users.delete msg.nick_canon
      @users[changed_nick_canon] = changed_user
    end

    def who_modes nick, info
      $log.debug("Channel.who_modes") { "#{nick} => #{info}" }

      nick = @connection.canonize nick

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
