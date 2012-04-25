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
  Connections = {}

  def self.run
    logsize  = Config[:core][:logsize]         rescue 1024000 
    logcount = Config[:core][:logcount]        rescue 5
    loglevel = Config[:core][:loglevel].upcase rescue "INFO"

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

    # Don't print warnings to STDERR.
    $-v = nil

    trap("INT")  { self.quit("Interrupted by host system. Exiting!") }
    trap("TERM") { self.quit("Terminated by host system. Exiting!") }
    trap("KILL") { exit }

    at_exit { self.clean_up }

    EM.error_handler { |e|
      $log.error("EM.error_handler") { e.to_s }
      $log.error("EM.error_handler") { e.backtrace.join("\n") }
    }

    Events.dispatch(:em_started)

    # TODO: Make this a config variable?
    EM.add_periodic_timer(300) { DB.write_database }

    bind = Config[:core][:bind]

    Config[:servers].each_pair do |name, config|
      if Connections.has_key? name
        $log.warn("Bot.run") { "Skipping duplicate connection: #{name}" }
        next
      end

      $log.debug("Bot.run") { "New connection: #{name}" }
      $log.debug("Bot.run") { config.to_s }

      unless bind == nil or bind.empty?
        EM.bind_connect(bind, config[:address], config[:port], IRCConnection, name)
      else
        EM.connect(config[:address], config[:port], IRCConnection, name)
      end
      
    end
  end

  def self.quit(message = "Terminus-Bot: Terminating")
    $log.debug("Bot.quit") { "Sending disconnection requests." }

    Connections.each_value do |connection|
      connection.disconnect(message)
    end

    try_exit
  end

  def self.try_exit
    count = EM.connection_count

    unless count.zero?
      $log.debug("Bot.try_exit") { "Waiting for connections to close (#{count} remaining)." }
      EM.add_timer(0.1) { self.try_exit }
    else
      exit
    end
  end

  def self.clean_up
    $log.debug("Bot.clean_up") { "Terminating event loop and deleting PID file." }

    EM.stop_event_loop if EM.reactor_running?
    File.delete(PID_FILE)
  end

end
