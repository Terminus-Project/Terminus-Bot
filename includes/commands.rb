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
  Command = Struct.new(:owner, :cmd, :func, :argc, :level, :chan_level, :help)

  class CommandManager < Hash

    def initialize
      Bot::Events.create(self, :PRIVMSG, :on_privmsg)
    end

    def on_privmsg(msg)
      prefix = Regexp.escape(Bot::Config[:core][:prefix])

      return unless msg.text =~ /\A#{msg.private? ? "(#{prefix})?" : "(#{prefix})"}([^ ]+)(.*)\Z/

        return unless has_key? $2

        command = self[$2]

        return unless Bot::Flags.permit_message?(command.owner, msg)

        level = msg.connection.users.get_level(msg)

        if command.level > level
          msg.reply("Level \02#{command.level}\02 authorization required. (Current level: #{level})")
          return
        end

        case command.chan_level

        when :voice
          unless msg.voice?
            msg.reply("You must be voiced or better to use this command.")
            return
          end

        when :half_op
          unless msg.half_op?
            msg.reply("You must be half-op or better to use this command.")
            return
          end

        when :op
          unless msg.op?
            msg.reply("You must be a channel op to use this command.")
            return
          end

        end

        # Split command parameters. If the command requires no parameters, put
        # everything in params[0].
        params = $3.strip.split(" ", command.argc.zero? ? 1 : command.argc)

        if params.length < command.argc
          # TODO: Show syntax.
          msg.reply("This command requires at least \02#{command.argc}\02 parameters.")
          return
        end

        $log.debug("CommandManager.on_privmsg") { "Match for command #{$2} in #{command.owner}" }

        begin
          command.owner.send(command.func, msg, params)
        rescue => e
          $log.error("CommandManager.on_privmsg") { "Problem running command #{$2} in #{command.owner}: #{e}" }
          $log.debug("CommandManager.on_privmsg") { e.backtrace }

          msg.reply("There was a problem running your command: #{e}")
        end
    end

    def create(owner, cmd, func, argc, level, chan_level, help)
      if has_key? cmd
        raise "attempted to register duplicate command #{cmd} for #{owner.class.name}"
      end

      $log.debug("CommandManager.create") { "Creating command: #{cmd}" }

      self[cmd] = Command.new(owner, cmd, func, argc, level, chan_level, help)
    end

    def delete(cmd)
      raise "attemped to delete non-existent command #{cmd}" unless has_key? cmd

      $log.debug("CommandManager.delete") { "Deleting command: #{cmd}" }

      super(cmd)
    end

    def delete_for(owner)
      $log.debug("CommandManager.delete_for") { "Unregistering all commands for #{owner.class.name}" }

      delete_if {|n,c| c.owner == owner}
    end

  end

  Commands = CommandManager.new
end
