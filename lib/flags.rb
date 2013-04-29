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
  class ScriptFlags < Hash

    # TODO: Use IRCConnection#canonize in here.

    def initialize
      @scripts = []

      # This is here because YAML doesn't know how to initialize us with it after
      # pulling the flags table back out of the database.
      # TODO: Correctly deal with rehashing since this likely won't pick up on it.
      @default_flag = Bot::Conf[:flags][:default] rescue true

      super
    end


    def add_server server
      self[server] ||= {}
    end

    # When adding a channel, the name MUST be canonized.
    def add_channel server, channel
      self[server][channel] ||= {}
    end


    # New script loaded. Add it if we don't already have it.
    def add_script name
      return if @scripts.include? name

      $log.debug("Flags.add_script") { name }

      @scripts << name
    end


    # Determine whether the given event should be sent or not, based on
    # the event itself and on the contents of the message
    def permit_message? owner, msg
      return true unless owner.is_a? Script

      # Always answer private messages!
      return true if msg.query?

      server  = msg.connection.name.to_s
      channel = msg.destination_canon
      name    = owner.my_short_name

      enabled? server, channel, name
    end

    # Return true if the script is enabled on the given server/channel. Otherwise,
    # return false.
    def enabled? server, channel, script
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
    def enable server_mask, channel_mask, script_mask
      set_flags server_mask, channel_mask, script_mask, 1
    end


    # Disable all matching scripts for all matching servers and channels (by
    # wildcard match).
    def disable server_mask, channel_mask, script_mask
      set_flags server_mask, channel_mask, script_mask, -1
    end


    # Do the hard work for enabling or disabling script flags. The last parameter
    # is the value which will be used for the flag.
    #
    # Returns the number of changed flags.
    def set_flags server_mask, channel_mask, script_mask, flag
      count = 0

      scripts = @scripts.select {|s| s.wildcard_match(script_mask)}
      privileged = Bot::Conf[:flags][:privileged].keys rescue []

      $log.debug("script_flags.set_flags") { "#{server_mask} #{channel_mask} #{script_mask} #{flag}" }
      $log.debug("script_flags.set_flags") { "#{scripts.length} matching scripts" }

      self.each_pair do |server, channels|
        next unless server.wildcard_match server_mask

        channels.each_pair do |channel, channel_scripts|
          next unless channel.wildcard_match channel_mask

          scripts.each do |script|

            next if privileged.include? script.to_sym and flag == -1

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

  load "lib/database.rb"

  unless defined? Flags
    if DB.has_key? :flags
      Flags = DB[:flags]
    else
      Flags = ScriptFlags.new
      DB[:flags] = Flags
    end
  end
end
