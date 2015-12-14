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
  class Command
    attr_reader :connection, :msg, :params

    include Bot::IRCMacros

    class << self

      # Run the command.
      #
      # A new {Command} will be instantiated and the command's block will be
      # evaluated in the context of the new object.
      #
      # @param owner [Object]
      # @param msg [Message] message that triggered the event
      # @param cmd [String] command that triggered the event
      # @param params [String] parameters supplied to the command
      # @param data [Hash] extra parameters for the event
      # @param blk [Block] block to eval for the event
      def run owner, msg, cmd, cmd_params, data = {}, &blk
        helpers(&owner.get_helpers)

        begin
          self.new(owner, msg, cmd, cmd_params, data).instance_eval(&blk)
        rescue Exception => e
          # TODO: rescue subset of Exception, if possible
          error msg, e
        end
      end

      # Notify to command caller of an error via IRC.
      #
      # @param msg [Message] the message that triggered the event which has
      #   taken an error
      # @param e [Exception]
      def error msg, e
        # XXX - this sort of sucks
        if msg.query?
          msg.connection.raw "NOTICE #{msg.nick} :Error: #{e}"
        else
          msg.connection.raw "PRIVMSG #{msg.destination} :#{msg.nick}: Error: #{e}"
        end

        $log.error('Command.run') { e }
        $log.error('Command.run') { e.backtrace }
      end

      # Evaluate helpers, if available.
      # @param blk [Block] block to eval
      def helpers &blk
        class_eval(&blk) if block_given?
      end
    end

    # @param owner [Object]
    # @param msg [Message] message that triggered the event
    # @param cmd [String] command that trigger the event
    # @param params [String] parameters supplied to the command
    # @param data [Hash] extra parameters for event
    def initialize owner, cmd_msg, cmd, cmd_params = "", data = {}
      @owner, @msg, @cmd, @data = owner, cmd_msg, cmd, data

      if cmd_params.nil?
        @params     = []
        @params_str = ""
      else
        @params_str = cmd_params
        @params     = cmd_params.split(/\s/)
      end

      @connection = cmd_msg.connection unless cmd_msg.nil?
    end

    # Pass unknown method calls to the command's parent object.
    #
    # @raise NoMethodError if the method does not exist on the parent
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
    # `arg` may be a {Hash}, Array, or {String}.
    #
    # @see Command#reply_without_prefix
    #
    # @param arg [Object] the message text to send
    # @param prefix [Boolean] if true and if the message is a channel message,
    #   include the speaker's nick in the reply
    def reply arg, prefix = true
      if arg.kind_of? Hash
        reply arg.to_s_irc, prefix
      elsif arg.kind_of? Array
        arg.each do |this_str|
          connection.send_reply msg, this_str, prefix
        end
      else
        connection.send_reply msg, arg, prefix
      end
    end

    # Send a reply to the message that triggered this command. Do not include a
    # nick prefix in the reply text.
    #
    # @see Command#reply
    #
    # @param arg [Object] the message text to send
    def reply_without_prefix arg
      reply arg, false
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
    def op? nick = @msg.nick
      query? or half_op? or voice? or @connection.channels[@msg.destination].op? nick
    end

    # Check if the speaker is a half-op or better.
    # @return [Boolean] true if half-op or private message
    def half_op? nick = @msg.nick
      query? or voice? or @connection.channels[@msg.destination].half_op? nick
    end

    # Check if the speaker is voiced or better.
    # @return [Boolean] true if voiced or private message
    def voice? nick = @msg.nick
      query? or @connection.channels[@msg.destination].voice? nick
    end

    # Check if the given module is loaded.
    # @return [Boolean] true if module is loaded
    def module_loaded? mod
      Bot::Modules.include? mod
    end

    # If the event is taking place in a channel, get the related {Channel}
    # object.
    #
    # @return [Object] {Channel} if exists, nil otherwise
    def channel
      return nil if msg.query?

      connection.channels[msg.destination]
    end

    # Return the {Channels} object for the current connection.
    #
    # @return [Channels] channels object for the current {IRCConnection}
    def channels
      connection.channels
    end

    # Require at least `count` command parameters and split the parameters into
    # the @params array. If there are more than `count` parameters provided,
    # the remainder are all included in the last element of @params.
    #
    # @raise if too few parameters are included
    #
    # @param count [Integer] minimum parameters required
    # @param syntax [String] optional syntax to include with exception message
    #
    # @return [Boolean] true if the minimum parameter count was met
    def argc! count, syntax = nil
      @params = @params_str.split(/\s/, count)

      return true if @params.length >= count

      if syntax
        raise "At least #{count} parameters required: #{syntax}"
      else
        raise "At least #{count} parameters required."
      end
    end

    # Require at least `count` command parameters and split the parameters into
    # the @params array. If there are more than `count` parameters provided,
    # the remainder are all included in the last element of @params.
    #
    # Additionally, the first item in @params will always be a channel name.
    # For messages sent in private, the channel name must be provided by the
    # user. For messages sent in a channel, the destination channel name will
    # always be used.
    #
    # @raise if too few parameters are included
    #
    # @param count [Integer] minimum parameters required
    # @param syntax [String] optional syntax to include with exception message
    #
    # @return [Boolean] true if the minimum parameter count was met
    def argc_channel! count, presence_required = false, syntax = nil
      if @msg.query?
        @params = @params_str.split(/\s/, count + 1)

        unless @connection.is_channel_name? @params.first
          raise 'The first parameter must be a valid channel name.'
        end
      else
        @params = @params_str.split(/\s/, count)
        @params.unshift @msg.destination
      end

      if presence_required
        unless @connection.channels.include? @connection.canonize @params.first
          raise 'I must be in the channel to use this command.'
        end
      end

      return true if @params.length >= count

      if syntax
        raise "At least #{count} parameters required: #{syntax}"
      else
        raise "At least #{count} parameters required."
      end
    end

    # Require the is logged in and has at least the account level specified.
    # @raise if failed
    # @param min [Integer] minimum account level required
    # @return [Boolean] true if account level is greater than or equal to `min`
    def level! min
      level = @connection.users[@msg.nick].level

      return true if level >= min

      raise 'Insufficient access level.'
    end

    # Require the message be sent in a channel.
    # @raise if failed
    # @return [Boolean] true if the message was sent in a channel
    def channel!
      return true unless query?

      raise 'This command may only be used in channels.'
    end

    # Require the message be sent in a private message.
    # @raise if failed
    # @return [Boolean] true if the message was sent in private
    def query!
      return true if query?

      raise 'This command may only be used in private.'
    end

    # Require the speaker have channel op.
    # @raise if failed
    # @return [Boolean] true if op or private message
    def op!
      return true if op?

      raise 'You must be a channel operator to use this command.'
    end

    # Require the speaker have channel half-op.
    # @raise if failed
    # @return [Boolean] true if half-op or private message
    def half_op!
      return true if half_op?

      raise 'You must be a channel half-operator to use this command.'
    end

    # Require the speaker have channel voice.
    # @raise if failed
    # @return [Boolean] true if voiced or private message
    def voice!
      return true if voice?

      raise 'You must be voiced to use this command.'
    end

    # @see IRCConnection#raw
    def raw *args
      @connection.raw(*args)
    end

    # @see IRCConnection#raw_fast
    def raw_fast *args
      @connection.raw_fast(*args)
    end
  end
end
# vim: set tabstop=2 expandtab:
