
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2012 Terminus-Bot Development Team
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

module Bot

  class Channels < Hash

    def initialize(connection)
      @connection = connection

      Bot::Events.create(self, :JOIN,  :on_join)
      Bot::Events.create(self, :PART,  :on_part)
      Bot::Events.create(self, :KICK,  :on_kick)
      Bot::Events.create(self, :MODE,  :on_mode)
      Bot::Events.create(self, :"324", :on_modes_on_join)

      Bot::Events.create(self, :QUIT,  :on_quit)

      Bot::Events.create(self, :TOPIC, :on_topic)
      Bot::Events.create(self, :"332", :on_topic_on_join) # topic on join

      Bot::Events.create(self, :"352", :on_who_reply) # who reply
      Bot::Events.create(self, :NAMES, :on_names)

      Bot::Events.create(self, :NICK,  :on_nick)
    end


    def on_who_reply(msg)
      return unless msg.connection == @connection
      canon_name = @connection.canonize(msg.raw_arr[3])

      unless has_key? canon_name
        self[canon_name] = Channel.new(canon_name, @connection)
      end

      self[canon_name].join(ChannelUser.new(@connection.canonize(msg.raw_arr[7]),
                                                     msg.raw_arr[4],
                                                     msg.raw_arr[5],
                                                     []))

      self[canon_name].who_modes(msg.raw_arr[7], msg.raw_arr[8])
    end


    def on_join(msg)
      return unless msg.connection == @connection

      unless has_key? msg.destination_canon
        self[msg.destination_canon] = Channel.new(msg.destination_canon, @connection)
        Bot::Flags.add_channel(@connection.name.to_s, msg.destination_canon)
      end

      if msg.me?
        msg.raw("MODE #{msg.destination}")
        msg.raw("WHO #{msg.destination}")
      end

      self[msg.destination_canon].join(ChannelUser.new(msg.nick_canon, msg.user, msg.host, []))
    end

    def on_part(msg)
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      if msg.me?
        return delete(msg.destination_canon)
      end

      self[msg.destination_canon].part(msg.nick_canon)
    end

    def on_kick(msg)
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      self[msg.destination_canon].part(@connection.canonize msg.raw_arr[3])
    end

    def on_mode(msg)
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      self[msg.destination_canon].mode_change(msg.raw_arr[3..-1])
    end

    def on_modes_on_join(msg)
      return unless msg.connection == @connection
      canon_name = @connection.canonize(msg.raw_arr[3])

      return unless has_key? canon_name

      self[canon_name].mode_change(msg.raw_arr[4..-1])
    end


    def on_topic(msg)
      return unless msg.connection == @connection

      return unless has_key? msg.destination_canon

      self[msg.destination_canon].topic(msg.text)
    end

    def on_topic_on_join(msg)
      return unless msg.connection == @connection
      canon_name = @connection.canonize(msg.raw_arr[3])

      return unless has_key? canon_name

      self[canon_name].topic(msg.text)
    end


    def on_quit(msg)
      return unless msg.connection == @connection

      # TODO: This is fucko. The Users class needs to hold channel users. We have
      # too much duplicate data.
      each_value do |c|
        c.part(msg.nick)
      end
    end

    def on_nick(msg)
      return unless msg.connection == @connection

      if msg.me?
        @nick = msg.text
        return
      end

      # TODO: This is fucko. The Users class needs to hold channel users. We have
      # too much duplicate data.
      each_value do |c|
        c.change_nick(msg)
      end
    end


  end

  # TODO: Track channel users in the user objects rather than here.
  ChannelUser = Struct.new(:nick, :user, :host, :modes)

  class Channel

    attr_reader :name, :topic, :modes, :users, :lists

    # Create the channel object. Since all we know when we join is the name,
    # that's all we're going to store here.
    def initialize(name, connection)
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
              @modes.delete(mode)
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
          param = @connection.canonize(param)

          if plus
            $log.debug("Channel.mode_change") { "Adding #{key} to #{param}" }
            @users[param].modes |= [key]
          else
            $log.debug("Channel.mode_change") { "Removing #{key} from #{param}" }
            @users[param].modes.delete(key)

            who = true
          end

        elsif chanmodes[0].include? key
          @lists[key] ||= []

          if plus
            @lists[key] |= [param]
          else
            @lists[key].delete(param)

            @lists.delete(key) if @lists[key].empty?
          end

        else
          if plus
            @modes[key] = param
          else
            @modes.delete(key)
          end
        end

      end

      @connection.raw("WHO #{@name}") if who and not @connection.caps.include? :multi_prefix
    end

    def op?(nick)
      nick = @connection.canonize(nick)

      return false unless @users.has_key? nick

      return true if @users[nick].modes.include? "q"
      return true if @users[nick].modes.include? "a"
      return true if @users[nick].modes.include? "o"

      # This is here for one IRCD that supports it. It shouldn't conflict with
      # anything else though.
      return true if @users[nick].modes.include? "y"

      false
    end

    def half_op?(nick)
      nick = @connection.canonize(nick)

      return false unless @users.has_key? nick

      return true if op? nick

      return false unless @users[nick].modes.include? "h"

      true
    end

    def voice?(nick)
      nick = @connection.canonize(nick)

      return false unless @users.has_key? nick

      return true if op? nick or half_op? nick

      return false unless @users[nick].modes.include? "v"

      true
    end

    # Store the topic.
    def topic(str)
      @topic = str
    end

    # Add a user to our channel's user list.
    def join(user)
      $log.debug("Channel.join") { "#{user.nick} joined #{@name}" }

      @users[@connection.canonize(user.nick)] = user
    end

    # Remove a user from our channel's user list.
    def part(nick)
      $log.debug("Channel.part") { "#{nick} parted #{@name}" }

      @users.delete(@connection.canonize(nick))
    end

    # Retrieve the channel user object for the named user, or return nil
    # if none exists.
    def get_user(nick)
      nick = @connection.canonize(nick)

      @users.has_key?(nick) ? @users[nick] : nil
    end

    # Someone changed nicks. Make the necessary updates.
    def change_nick(msg)
      return unless @users.has_key? msg.nick_canon

      $log.debug("Channel.change_nick") { "Renaming user #{msg.nick} on #{@name}" }

      changed_nick_canon = msg.connection.canonize(msg.text)

      # Apparently structs don't let you change values. So just make a
      # new user.
      changed_user = ChannelUser.new(changed_nick_canon,
                                     @users[msg.nick_canon].user,
                                     @users[msg.nick_canon].host,
                                     @users[msg.nick_canon].modes)

      @users.delete(msg.nick_canon)
      @users[changed_nick_canon] = changed_user
    end

    def who_modes(nick, info)
      $log.debug("Channel.who_modes") { "#{nick} => #{info}" }

      nick = @connection.canonize(nick)

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
