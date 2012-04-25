#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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
  Command = Struct.new(:owner, :cmd, :func, :argc, :level, :chan_level, :help)

  class CommandManager < Hash

    def initialize
      Bot::Events.create(self, :PRIVMSG, :on_privmsg)
    end

    def on_privmsg(msg)
      return if msg.silent?

      return unless msg.text =~ /\A#{msg.private? ?
        "(#{Bot::Config[:core][:prefix]})?" :
        "(#{Bot::Config[:core][:prefix]})"}([^ ]+)(.*)\Z/

        return unless has_key? $2

        command = self[$2]

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
          command.owner.send(command.func, msg, params) if Bot::Flags.permit_message?(command.owner, msg)
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
