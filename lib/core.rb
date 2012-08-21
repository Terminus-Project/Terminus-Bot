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
  Connections ||= {}

  def self.run
    logsize  = Bot::Conf[:core][:logsize]         rescue 1024000 
    logcount = Bot::Conf[:core][:logcount]        rescue 5
    loglevel = Bot::Conf[:core][:loglevel].upcase rescue "INFO"

    if $opts[:fork]
      $log.close
      $log = Logger.new 'var/terminus-bot.log', logcount, logsize
    end

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

    trap("INT")  { self.quit "Interrupted by host system. Exiting!" }
    trap("TERM") { self.quit "Terminated by host system. Exiting!" }
    trap("KILL") { exit }

    at_exit { self.clean_up }

    EM.error_handler { |e|
      $log.error("EM.error_handler") { e.to_s }
      $log.error("EM.error_handler") { e.backtrace.join "\n" }
    }

    Events.dispatch :em_started

    # TODO: Make this a config variable?
    EM.add_periodic_timer(300) { DB.write_database }

    bind = Bot::Conf[:core][:bind]

    Bot::Conf[:servers].each_pair do |name, config|
      if Connections.has_key? name
        $log.warn("Bot.run") { "Skipping duplicate connection: #{name}" }
        next
      end

      $log.debug("Bot.run") { "New connection: #{name}" }
      $log.debug("Bot.run") { config.to_s }

      unless bind == nil or bind.empty?
        EM.bind_connect bind, config[:address], config[:port], IRCConnection, name
      else
        EM.connect config[:address], config[:port], IRCConnection, name
      end
      
    end
  end

  def self.quit message = "Terminus-Bot: Terminating"
    $log.debug("Bot.quit") { "Sending disconnection requests." }

    Connections.each_value do |connection|
      connection.disconnect message
    end

    Scripts.die

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
    File.delete PID_FILE
  end

end
