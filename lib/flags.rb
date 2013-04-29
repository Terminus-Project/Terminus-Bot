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


    # Prepare ScriptFlags object for use. The default flags value is read from
    # configuration during initialization and stored in a class variable.
    def initialize
      @scripts = []

      # This is here because YAML doesn't know how to initialize us with it after
      # pulling the flags table back out of the database.
      # TODO: Correctly deal with rehashing since this likely won't pick up on it.
      @default_flag = Bot::Conf[:flags][:default] rescue true

      super
    end

    # Create a new flags database for a server if one does not yet exist.
    #
    # @param server [String] server name
    # @return [Hash] flags database for the server
    def add_server server
      self[server] ||= {}
    end

    # Create a new flags database for a channel if one does not yet exist.
    #
    # @param server [String] server name
    # @param channel [String] canonized channel name
    # @return [Hash] flags database for the channel
    def add_channel server, channel
      self[server][channel] ||= {}
    end

    # Add a script to the flags pool if it is not already there. Called any
    # time a script is loaded.
    #
    # Note that scripts are never removed from the database since we don't want
    # to forget their flags.
    #
    # @param name [String] script name
    # @return [Array] script list
    def add_script name
      return if @scripts.include? name

      $log.debug("Flags.add_script") { name }

      @scripts << name
    end


    # Determine if the message is permitted by flags settings.
    #
    # Always returns true if `owner` is not a {Script}.
    #
    # @see ScriptFlags#enabled?
    #
    # @param owner [Object] message owner
    # @param msg [Message] message for which to perform the check
    # @return [Boolean] true if caller can proceed, false if not
    def permit_message? owner, msg
      return true unless owner.is_a? Script

      # Always answer private messages!
      return true if msg.query?

      server  = msg.connection.name.to_s
      channel = msg.destination_canon
      name    = owner.my_short_name

      enabled? server, channel, name
    end

    # Check if a script is enabled for a particular channel. If no flag is set,
    # the default is returned.
    #
    # @param server [String] server name
    # @param channel [String] canonized channel name
    # @param script [String] script name
    # @return [Boolean] true if script is enabled, false if not
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


    # Mark one or more scripts as enabled for one or more channels. Wildcards
    # are supported in any parameter.
    #
    # @see ScriptFlags#set_flags
    #
    # @param server_mask [String] server name (supports wildcard match)
    # @param channel_mask [String] channel name (supports wildcard match)
    # @param script_mask [String] script name (supports wildcard match)
    def enable server_mask, channel_mask, script_mask
      set_flags server_mask, channel_mask, script_mask, 1
    end


    # Mark one or more scripts as disabled for one or more channels. Wildcards
    # are supported in any parameter.
    #
    # @see ScriptFlags#set_flags
    #
    # @param server_mask [String] server name (supports wildcard match)
    # @param channel_mask [String] channel name (supports wildcard match)
    # @param script_mask [String] script name (supports wildcard match)
    def disable server_mask, channel_mask, script_mask
      set_flags server_mask, channel_mask, script_mask, -1
    end


    # Change flags for one or more scripts. This should **typically** not be
    # called directly. Instead, you probably want {ScriptFlags#enable} or
    # {ScriptFlags#disable}.
    #
    # @see ScriptFlags#enable
    # @see ScriptFlags#disable
    #
    # @param server_mask [String] server name (supports wildcard match)
    # @param channel_mask [String] channel name (supports wildcard match)
    # @param script_mask [String] script name (supports wildcard match)
    # @param flag [Interger] -1 to disable, 0 to reset, 1 to enable
    #
    # @return [Interger] number of flags that were changed
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
