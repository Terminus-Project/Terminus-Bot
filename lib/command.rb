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
  class Command
    #attr_reader :owner, :cmd, :func, :argc, :level, :chan_level, :help

    include Bot::IRCMacros

    class << self
      def run owner, msg, cmd, params, data = {}, &blk
        helpers &owner.get_helpers

        begin
          self.new(owner, msg, cmd, params, data).instance_eval &blk
        rescue Exception => e
          error msg, e
        end
      end

      def error msg, e
          # XXX - this sort of sucks
          if msg.query?
            msg.connection.raw "NOTICE #{msg.nick} :Error: #{e.to_s}"
          else
            msg.connection.raw "PRIVMSG #{msg.destination} :#{msg.nick}: Error: #{e.to_s}"
          end

          $log.error('Command.run') { e }
          $log.error('Command.run') { e.backtrace }
      end

      def helpers &blk
        class_eval &blk if block_given?
      end
    end

    def initialize owner, msg, cmd, params = "", data = {}
      @owner, @msg, @cmd, @data = owner, msg, cmd, data

      if params.nil?
        @params     = []
        @params_str = ""
      else
        @params_str = params
        @params     = params.split(/\s/)
      end

      @connection = msg.connection unless msg.nil?
    end

    # Pass unknown method calls to the command's parent object.
    #
    # XXX - This sucks.
    def method_missing name, *args, &block
      if @owner.respond_to? name
        @owner.send name, *args, &block
      else
        $log.error("Script.method_missing") { "Attempted to call nonexistent method #{name}" }
        raise NoMethodError.new("#{my_name} attempted to call a nonexistent method #{name}", name, args)
      end
    end

    # TODO: move remaining helpers from @msg to here.


    # Send a reply to the message that triggered this command. The message
    # destination is determined by the origin:
    #
    # * If the message was sent to a channel, reply in the channel.
    # * If the message was sent in private, reply with a private NOTICE.
    #
    # @param str [String] the message text to send
    # @param prefix [Boolean] if true and if the message is a channel message,
    #   include the speaker's nick in the reply
    def reply str, prefix = true
      if str.kind_of? Hash
        reply str.to_s_irc, prefix
      elsif str.kind_of? Array
        str.each do |this_str|
          @connection.send_reply @msg, this_str, prefix
        end
      else
        @connection.send_reply @msg, str, prefix
      end
    end

    # Check if the message was sent in private
    # @return [Boolean] true if private message
    def query?
      @private ||= (not @connection.support("CHANTYPES", "#&").include? @msg.destination.chr)
    end

    # Check if the message was sent to a channel.
    # @return [Boolean] true if channel message
    def channel?
      not query?
    end

    # Check if the speaker is the bot.
    # @return [Boolean] true if the bot's nick matches the speaker's
    def me?
      @msg.me?
    end

    # Check if the speaker is op or better.
    # @return [Boolean] true if op or private message
    def op?
      query? or half_op? or voice? or @connection.channels[@msg.destination_canon].op? @msg.nick
    end

    # Check if the speaker is a half-op or better.
    # @return [Boolean] true if half-op or private message
    def half_op?
      query? or voice? or @connection.channels[@msg.destination_canon].half_op? @msg.nick
    end

    # Check if the speaker is voiced or better.
    # @return [Boolean] true if voiced or private message
    def voice?
      query? or @connection.channels[@msg.destination_canon].voice? @msg.nick
    end

    # Require at least `count` command parameters and split the parameters into
    # the @params array. If there are more than `count` parameters provided,
    # the remainder are all included in the last element of @params.
    #
    # If too few parameters are included, an exception is raised.
    #
    # @param count [Integer] minimum parameters required
    # @param syntax [String] optional syntax to include with exception message
    def argc! count, syntax = nil
      @params = @params_str.split(/\s/, count)

      return true if @params.length >= count

      if syntax
        raise "At least #{count} parameters required: #{syntax}"
      else
        raise "At least #{count} parameters required."
      end
    end

    # Require the is logged in and has at least the account level specified.
    # Raises an exception if failed.
    # @param min [Integer] minimum account level required
    # @return [Boolean] true if account level is greater than or equal to `min`
    def level! min
      level = @connection.users[@msg.nick_canon].level

      return true if level >= min

      raise 'Insufficient access level.'
    end

    # Require the message be sent in a channel. Raises an exception if failed.
    # @return [Boolean] true if the message was sent in a channel
    def channel!
      return true unless query?

      raise 'This command may only be used in channels.'
    end

    # Require the message be sent in a private message. Raises an exception if
    # failed.
    # @return [Boolean] true if the message was sent in private
    def query!
      return true if query?

      raise 'This command may only be used in private.'
    end

    # Require the speaker have channel op. Raises an exception if failed.
    # @return [Boolean] true if op or private message
    def op!
      return true if op?

      raise 'You must be a channel operator to use this command.'
    end

    # Require the speaker have channel half-op. Raises an exception if failed.
    # @return [Boolean] true if half-op or private message
    def half_op!
      return true if half_op?

      raise 'You must be a channel half-operator to use this command.'
    end

    # Require the speaker have channel voice. Raises an exception if failed.
    # @return [Boolean] true if voiced or private message
    def voice!
      return true if voice?

      raise 'You must be voiced to use this command.'
    end

    # @see IRCConnection#raw
    def raw *args
      @connection.raw *args
    end
  end
end
