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
          @connection.send_reply @msg, this_str, prefix
        end
      else
        @connection.send_reply @msg, str, prefix
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

    def send_privmsg *args
      @connection.send_privmsg *args
    end

    def send_notice *args
      @connection.send_notice *args
    end

    def raw *args
      @connection.raw *args
    end
  end
end
