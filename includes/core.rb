

#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
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


module Terminus_Bot

  class Bot

    attr_reader :config, :connections, :events, :database, :commands, :script_info, :scripts

    VERSION = "Terminus-Bot v0.5"

    Command = Struct.new(:owner, :cmd, :func, :argc, :level, :help)
    Script_Info = Struct.new(:name, :description)

    def initialize
      $bot = self

      @connections = Hash.new
      @config = Configuration.new
      @database = Database.new
      @commands = Array.new
      @script_info = Array.new
      @events = Events.new
      @scripts = Scripts.new

      @events.create(self, "PRIVMSG", :run_commands)

      config['core']['servers'].split(" ").each do |server_config|
        server_config = server_config.split(":")

        $log.debug("Bot.initialize") { "Working on server config for #{server_config[0]}" }

        @connections[server_config[0]] = IRC::Connection.new(server_config[0],
                                                             server_config[1],
                                                             server_config[2],
                                                             config["core"]["bind"],
                                                             server_config[3],
                                                             config["core"]["nick"],
                                                             config["core"]["user"],
                                                             config["core"]["realname"])
      end

      trap("INT"){ quit("Interrupted by host system. Exiting!") }
      trap("TERM"){ quit("Terminated by host system. Exiting!") }
      trap("KILL"){ exit } # Kill (signal 9) is pretty hardcore. Just exit!
      
      trap("HUP", "IGNORE") # We don't need to die on HUP.
                            # TODO: Rehash?
      
      at_exit { quit }

      @connections.values.last.read_thread.join
    end

    def run_commands(msg)
      return unless msg.text =~ /\A#{@config['core']['prefix']}([^ ]+)(.*)\Z/

      $log.debug("Bot.run_commands") { "Running command #{$1} from #{msg.origin}" }

      @commands.each do |command|
        $log.debug("Bot.run_commands") { "Checking #{command.cmd}" }

        if command.cmd == $1

          level = msg.connection.users.get_level(msg)

          if command.level > level
            msg.reply("Level \02#{command.level}\02 authorization required. (Current level: #{level})")
            return
          end

          params = Array.new
          params_raw = $2.strip.split(" ")

          if params_raw.length < command.argc
            msg.reply("This command requires at least \02#{command.argc}\02 parameters.")
            return
          end

          (0..command.argc - 1).each do |i|
            if i == command.argc - 1
              params << params_raw[i..params_raw.length-1].join(" ")
            else
              params << params_raw[i]
            end
          end

          $log.debug("Bot.run_commands") { "Match for command #{$1} in #{command.owner}" }

          begin
            command.owner.send(command.func, msg, params)
            return
          rescue => e
            $log.error("Bot.run_commands") { "Problem running command #{$1} in #{command.owner}: #{e}" }
            msg.reply("There was a problem running your command: #{e}")
          end

        end

      end
    end

    def quit(str = "Terminus-Bot: Terminating")
      @connections.each_value do |connection|
        connection.disconnect(str)
      end

      exit
    end

    def register_command(*args)
      $log.debug("Bot.register_command") { "Registering command." }

      @commands << Command.new(*args)
    end

    def register_script(*args)
      $log.debug("Bot.register_script") { "Registering script." }

      @script_info << Script_Info.new(*args)
    end

    def unregister_script(name)
      $log.debug("Bot.unregister_script") { "Unregistering script #{name}" }
      @script_info.delete_if {|s| s.name == name}
    end

    def unregister_command(cmd)
      $log.debug("Bot.unregister_command") { "Unregistering command #{cmd}" }
      @commands.delete_if {|c| c.cmd == cmd}
    end

    def unregister_commands(owner)
      $log.debug("Bot.unregister_commands") { "Unregistering all commands for #{owner.class.name}" }
      @commands.delete_if {|c| c.owner == owner}
    end

    def unregister_events(owner)
      $log.debug("Bot.unregister_events") { "Unregistering all events for #{owner.class.name}" }
      @events.delete_events_for(owner)
    end

  end

end
