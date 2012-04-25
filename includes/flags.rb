
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
  class Script_Flags < Hash

    # TODO: Use IRCConnection#canonize in here.

    def initialize
      @scripts = []

      # This is here because YAML doesn't know how to initialize us with it after
      # pulling the flags table back out of the database.
      # TODO: Correctly deal with rehashing since this likely won't pick up on it.
      @default_flag = Bot::Config[:flags][:default] rescue true

      super
    end


    def add_server(server)
      self[server] ||= Hash.new
    end


    def add_channel(server, channel)
      self[server][channel] ||= Hash.new
    end


    # New script loaded. Add it if we don't already have it.
    def add_script(name)
      return if @scripts.include? name

      $log.debug("Flags.add_script") { name }

      @scripts << name
    end


    # Determine whether the given event should be sent or not, based on
    # the event itself and on the contents of the message
    def permit_message?(owner, msg)
      return true unless owner.is_a? Script

      # Always answer private messages!
      return true if msg.private?

      server  = msg.connection.name.to_s
      channel = msg.destination
      name    = owner.my_short_name

      enabled?(server, channel, name)
    end

    # Return true if the script is enabled on the given server/channel. Otherwise,
    # return false.
    def enabled?(server, channel, script)
      flag = self[server][channel][script] rescue 0

      case flag
      when -1
        return false
      when 1
        return true
      end

      @default_flag
    end


    # Enable all matching scripts for all matching servers and channels (by
    # wildcard match).
    def enable(server_mask, channel_mask, script_mask)
      set_flags(server_mask, channel_mask, script_mask, 1)
    end


    # Disable all matching scripts for all matching servers and channels (by
    # wildcard match).
    def disable(server_mask, channel_mask, script_mask)
      set_flags(server_mask, channel_mask, script_mask, -1)
    end


    # Do the hard work for enabling or disabling script flags. The last parameter
    # is the value which will be used for the flag.
    #
    # Returns the number of changed flags.
    def set_flags(server_mask, channel_mask, script_mask, flag)
      count = 0

      scripts = @scripts.select {|s| s.wildcard_match(script_mask)}
      privileged = Bot::Config[:flags][:privileged].split(/,\s*/) rescue []

      $log.debug("script_flags.set_flags") { "#{server_mask} #{channel_mask} #{script_mask} #{flag}" }
      $log.debug("script_flags.set_flags") { "#{scripts.length} matching scripts" }

      self.each_pair do |server, channels|
        next unless server.wildcard_match(server_mask)

        channels.each_pair do |channel, channel_scripts|
          next unless channel.wildcard_match(channel_mask)

          scripts.each do |script|

            next if privileged.include? script and flag == -1

            if channel_scripts[script] != flag
              channel_scripts[script] = flag
              count += 1
            end

          end
        end
      end

      count
    end
  end

  load "includes/database.rb"

  if DB.has_key? :flags
    Flags = DB[:flags]
  else
    Flags = Script_Flags.new
    DB[:flags] = Flags
  end
end
