

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


DATA_DIR = "var/terminus-bot/"

class Bot

  attr :connections
  attr_reader :config, :events, :database, :commands, :script_info, :scripts

  Command = Struct.new(:owner, :cmd, :func, :argc, :level, :help)
  Script_Info = Struct.new(:name, :description)

  # This starts the whole thing.
  def initialize

    # Dirty? A bit. TODO: Get rid of this. Maybe.
    $bot = self

    $-v = nil

    @connections = Hash.new       # IRC objects. Keys are configured names.

    @config = Configuration.new   # Configuration. Extends Hash.

    @database = Database.new      # Scripts can store data here.

    @commands = Hash.new          # An hash table of Commands (see the above Struct).
                                  # These are fired like events.
    
    @script_info = Array.new      # Name and description for scripts (see above Struct).

    @events = Events.new          # We're event-driven. See includes/event.rb

    @scripts = Scripts.new        # For those things in the scripts dir.

    logsize = @config['core']['logsize'].to_i rescue 1024000 
    logcount = @config['core']['logcount'].to_i rescue 5
    loglevel = @config['core']['loglevel'].upcase rescue "INFO"

    $log.close
    $log = Logger.new('var/terminus-bot.log', logcount, logsize);

    case loglevel
    when "FATAL"
      $log.level = Logger::FATAL
    when "ERROR"
      $log.level = Logger::ERROR
    when "WARN"
      $log.level = Logger::WARN
    when "INFO"
      $log.level = Logger::INFO
    when "DEBUG"
      $log.level = Logger::DEBUG
    else
      $log.level = Logger::INFO
    end

    # The only event we care about in the core.
    @events.create(self, "PRIVMSG", :run_commands)

    # Since we made it this far, go ahead and be ready for signals.
    trap("INT")  { quit("Interrupted by host system. Exiting!") }
    trap("TERM") { quit("Terminated by host system. Exiting!") }
    trap("KILL") { exit }
    
    trap("HUP", $bot.config.read_config ) # Rehash on HUP!
    
    # Try to exit cleanly if we have to.
    at_exit { quit }

    Dir.mkdir("var") unless Dir.exists? "var"
    Dir.mkdir(DATA_DIR) unless Dir.exists? DATA_DIR

    EM.run do
      EM.error_handler { |e|
        $log.error("EM.error_handler") { e.to_s }
        $log.error("EM.error_handler") { e.backtrace }
      }

      # Begin connecting
      start_connections
    end
  end

  # Iterate through configured connections and connect to servers we should
  # connect to. Also disconnect from servers that aren't configured (for
  # rehashing).
  def start_connections

    # Keep a list of configured servers for later.
    servers = Array.new

    @config['core']['servers'].split(" ").each do |server_config|
      server_config = server_config.split(":")

      $log.debug("Bot.start_connections") { "Working on server config for #{server_config[0]}" }

      servers << server_config[0]

      if @connections.has_key? server_config[0]
        $log.info("Bot.start_connections") { "Skipping existing connection #{server_config[0]}" }
        next
      end

      if config["core"]["bind"] != nil
        EM.bind_connect(config["core"]["bind"], rand(64511)+1024,
                        server_config[1], server_config[2], IRC_Connection,
                        server_config[0], server_config[1], 
                        server_config[2], server_config[3], config['core']['bind'],
                        config['core']['nick'], config['core']['user'], config['core']['realname'])
      else
        EM.connect(server_config[1], server_config[2], IRC_Connection,
                   server_config[0], server_config[1], 
                   server_config[2], server_config[3], config['core']['bind'],
                   config['core']['nick'], config['core']['user'], config['core']['realname'])
      end

    end

    # Iterate through servers and remove @connections that should't be there
    # anymore (useful for rehashing away connections).
    @connections.each do |name, connection|
      next if servers.include? name

      connection.disconnect
      connection.close
      @connections.delete(name)
    end
  end

  # Fired on PRIVMSGs.
  # Iterate through @commands and run everything that needs to be run.
  def run_commands(msg)
    return if msg.silent?

    return unless msg.text =~ /\A#{msg.private? ?
      '(' + @config['core']['prefix'] + ')?' :
      '(' + @config['core']['prefix'] + ')'}([^ ]+)(.*)\Z/

    $log.debug("Bot.run_commands") { "Running command #{$2} from #{msg.origin}" }

    return unless @commands.has_key? $2

    command = @commands[$2]

    level = msg.connection.users.get_level(msg)

    if command.level > level
      msg.reply("Level \02#{command.level}\02 authorization required. (Current level: #{level})")
      return
    end

    if command.argc == 0
      params = $3.strip.split(" ", 1)
    else
      params = $3.strip.split(" ", command.argc)
    end

    if params.length < command.argc
      msg.reply("This command requires at least \02#{command.argc}\02 parameters.")
      return
    end

    $log.debug("Bot.run_commands") { "Match for command #{$2} in #{command.owner}" }

    begin
      command.owner.send(command.func, msg, params)
    rescue => e
      $log.error("Bot.run_commands") { "Problem running command #{$2} in #{command.owner}: #{e}" }
      $log.debug("Bot.run_commands") { "Problem running command #{$2} in #{command.owner}: #{e.backtrace}" }
      msg.reply("There was a problem running your command: #{e}")
    end

  end

  # Send QUITs and do any other work that needs to be done before exiting.
  def quit(str = "Terminus-Bot: Terminating")
    @connections.each_value do |connection|
      connection.disconnect(str)
    end

    @scripts.die

    $log.debug("Bot.quit") { "Removing PID file #{PID_FILE}" }
    File.delete(PID_FILE) if File.exists? PID_FILE

    exit
  end

  # Register a command. See the Commands struct for the args.
  def register_command(owner, cmd, func, argc, level, help)
    $log.debug("Bot.register_command") { "Registering command." }

    if @commands.has_key? cmd
      throw "Duplicate command registration: #{cmd}"
    end

    @commands[cmd] = Command.new(owner, cmd, func, argc, level, help)
  end

  # Register a script. See the Script_Info struct for args.
  def register_script(*args)
    $log.debug("Bot.register_script") { "Registering script." }

    @script_info << Script_Info.new(*args)
    @script_info.sort_by! {|s| s.name}
  end

  # Remove a script from @scripts (by name).
  def unregister_script(name)
    $log.debug("Bot.unregister_script") { "Unregistering script #{name}" }
    @script_info.delete_if {|s| s.name == name}
  end

  # Unregister a specific command. This doesn't check for ownership
  # and removes all matching commands by name.
  def unregister_command(cmd)
    $log.debug("Bot.unregister_command") { "Unregistering command #{cmd}" }
    @commands.delete(cmd)
  end

  # Unregister all commands owned by the given class.
  def unregister_commands(owner)
    $log.debug("Bot.unregister_commands") { "Unregistering all commands for #{owner.class.name}" }
    @commands.delete_if {|n, c| c.owner == owner}
  end

  # Unregister all events owned by the given class.
  def unregister_events(owner)
    $log.debug("Bot.unregister_events") { "Unregistering all events for #{owner.class.name}" }
    @events.delete_events_for(owner)
  end

end

