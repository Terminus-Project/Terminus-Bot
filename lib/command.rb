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
  class Command
    #attr_reader :owner, :cmd, :func, :argc, :level, :chan_level, :help

    class << self
      def run owner, msg, cmd, params, data = {}, &blk
        helpers &owner.get_helpers

        begin
          self.new(owner, msg, cmd, params, data).instance_eval &blk
        rescue Exception => e
          # XXX - this sort of sucks
          if msg.query?
            msg.connection.raw "NOTICE #{msg.nick} :Error: #{e.to_s}"
          else
            msg.connection.raw "PRIVMSG #{msg.destination} :#{msg.nick}: Error: #{e.to_s}"
          end

          $log.error('Command.run') { e }
          $log.error('Command.run') { e.backtrace }
        end
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

    def reply str, prefix = true
      if str.kind_of? Array
        str.each do |this_str|
          send_reply this_str, prefix
        end
      else
        send_reply str, prefix
      end
    end

    def query?
      @private ||= (not @connection.support("CHANTYPES", "#&").include? @msg.destination.chr)
    end

    def channel?
      not query?
    end

    def me?
      @msg.me?
    end

    def op?
      query? or half_op? or voice? or @connection.channels[@msg.destination_canon].op? @msg.nick
    end

    def half_op?
      query? or voice? or @connection.channels[@msg.destination_canon].half_op? @msg.nick
    end

    def voice?
      query? or @connection.channels[@msg.destination_canon].voice? @msg.nick
    end

    # require 'count' args, send optional syntax on failure
    def argc! count, syntax = nil
      @params = @params_str.split(/\s/, count)

      return true if @params.length >= count

      if syntax
        raise "At least #{count} parameters required: #{syntax}"
      else
        raise "At least #{count} parameters required."
      end
    end

    # require sender to have minimum admin level
    def level! min
      level = @connection.users[@msg.nick_canon].level

      return true if level >= min

      raise 'Insufficient access level.'
    end

    def channel!
      return true unless query?

      raise 'This command may only be used in channels.'
    end

    # command must be used in private
    def query!
      return true if query?

      raise 'This command may only be used in private.'
    end

    def op!
      return true if op?

      raise 'You must be a channel operator to use this command.'
    end

    def half_op!
      return true if half_op?

      raise 'You must be a channel half-operator to use this command.'
    end

    def voice!
      return true if voice?

      raise 'You must be voiced to use this command.'
    end

    def send_privmsg dest, msg
      raw "PRIVMSG #{dest} :#{msg}"
    end

    def send_notice dest, msg
      raw "NOTICE #{dest} :#{msg}"
    end

    def raw *args
      @connection.raw *args
    end

    private

    # Actually send the reply. If prefix is true, prefix each message with the
    # triggering user's nick. If replying in private, never use a prefix, and
    # reply with NOTICE instead.
    def send_reply str, prefix
      if str.empty?
        str = "I tried to send you an empty message. Oops!"
      end

      # TODO: Hold additional content for later sending or something.
      #       Just don't try to send it all in multiple messages without
      #       the user asking for it!
      unless @msg.query?
        str = "#{@msg.nick}: #{str}" if prefix

        send_privmsg @msg.destination, str
      else
        send_notice @msg.nick, str
      end
    end

    # Attempt to truncate messages in such a way that the maximum
    # amount of space possible is used. This assumes the server will
    # send a full 512 bytes to a client with exactly 1459 format.
    def truncate message, destination, notice = false
      prefix_length = @connection.nick.length +
        @connection.user.length +
        @connection.client_host.length +
        destination.length +
        15

      # PRIVMSG is 1 char longer than NOTICE
      prefix_length += 1 unless notice

      if (prefix_length + message.length) - 512 > 0
        return message[0..511-prefix_length]
      end

      message
    end

  end
end
