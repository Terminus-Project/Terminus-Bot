#!/usr/bin/ruby

require 'socket'
require 'logger'

class TerminusBot

  def initialize(server, port, channels)
    @channels = channels
    @network = Network.new()
    $socket = TCPSocket.open(server, port)
    say "NICK " + BOTNICK
    say "USER #{BOTIDENT} 0 * #{BOTNAME}"
  end

  def say(msg)
    $socket.puts(msg)
  end

  def say_to_chan(msg, channel)
    sendMessage("PRIVMSG #{channel} :#{msg}")
  end

  def run
    until $socket.eof? do
      msg = $socket.gets
      #puts msg

      # go ahead and handle server PING first
      if msg.match(/^PING :(.*)$/)
        say "PONG #{$~[1]}"
        next
      end
      
      msgArr = msg.match(/^:?(.*)$/)[1].split(/ /)

      case msgArr[1]
        when "PRIVMSG"
          content = msg.match(/PRIVMSG .* :(.*)$/)[1]
          message = IRCMessage.new(msgArr[2], content, msgArr[0])

          # echo it! - probably need to move this elsewhere
          puts "[#{message.timestamp}] <#{message.speaker.nick}:#{message.origin}> #{message.message}"
          attemptHook(message.msgArr[0], message)
        when "NOTICE"
          content = msg.match(/NOTICE .* :(.*)$/)[1]
          message = IRCMessage.new(msgArr[2], content, msgArr[0])

          # echo it! - probably need to move this elsewhere
          puts "[#{message.timestamp}] --#{message.speaker.nick}:#{message.origin}-- #{message.message}"

        when "004"
          @network.currentServer = msgArr[3]
          @network.serverSoftware = msgArr[4]
        when "005"
          msgArr.each { |param|
            paramArr = param.split("=")
            case paramArr[0]
              when "NETWORK"
                @network.name = paramArr[1]
              when "MAXCHANNELS"
                @network.maxChannels = paramArr[1]
              when "CHANNELLEN"
                @network.maxChannelNameLength = paramArr[1]
              when "TOPICLEN"
                @network.maxTopicLength = paramArr[1]
              when "KICKLEN"
                @network.maxKickLength = paramArr[1]
              when "AWAYLEN"
                @network.maxAwayLength = paramArr[1]
              when "MAXTARGETS"
                @network.maxTargets = paramArr[1]
              when "MODES"
                @network.maxModes = paramArr[1]
              when "CHANTYPES"
                @network.channelTypes = paramArr[1]
              when "CHANMODES"
                @network.channelModes = paramArr[1]
              when "CASEMAPPING"
                @network.caseMapping = paramArr[1]
              when "PREFIX"
                @network.prefixes = paramArr[1]
              when "MAXLIST"
                maxListArrs = paramArr[1].split(",")
                maxListArrs.each { |maxListArr|
                  maxListArr = maxListArr.split(":")                  
                  if maxListArr[0] == "b"
                    @network.maxBans = maxListArr[1]
                  elsif maxListArr[0] == "e"
                    @network.maxExempts = maxListArr[1]
                  elsif maxListArr[0] == "I"
                    @network.maxInviteExempts = maxListArr[1]
                  else
                    $log.warn('parser') { "Invalid MAXLIST parameter: #{maxListArr.join(":")}" }
                  end
                }
          
            end
          }

        when "353" #names list
          names = msg.match(/.*:(.*)/)
          names = names[1].split(" ")
          names.each { |name|
            # these will go into a channel object once that's ready
          }
        when "366" #end of names list

        when "376" #end of motd
          say "JOIN #{@channels}"
          
        when "422" #motd not found
          say "JOIN #{@channels}"

	#else
        #  puts "Unknown message type: #{msg}"
      end

      next
    end
  end

  def quit(quitMessage = "Terminus-Bot: Terminating.")
    say 'QUIT ' + quitMessage
  end

  def attemptHook(cmd, msg)
    if cmd.match(/\A#{CMDPREFIX}(.*)/)
      cmd = $~[1]
      
      $modules.each do |m|
         m.send("cmd_#{cmd}",msg) unless not m.respond_to?("cmd_#{cmd}")
         $log.debug('bot') { "attemptHook #{m} -> cmd_#{cmd}" }
      end
    end
  end
end

$log = Logger.new('logs/system.log', 'weekly');

$log.info('init') { 'Terminus-Bot is now starting.' }

$log.debug('init') { 'Loading configuration.' }
puts "Loading configuration..."
load "conf.rb"

$log.debug('init') { 'Loading core bot files.' }
puts "Loading bot core..."
Dir.foreach("classes") { |f| load "./classes/#{f}" unless f.match(/^\.+$/) }

$log.debug('init') { 'Loading modules.' }
puts "Loading modules..."
$modules = Array.new()
Dir.foreach("modules") { |f| load "./modules/#{f}" unless f.match(/^\.+$/) }

$log.debug('init') { 'Firing off the bot.' }
puts "Done. Establishing IRC connection..."
bot = TerminusBot.new(SERVER, PORT, CHANNELS)

$log.info('init') { 'Bot started! Now running.' }
puts "Terminus-Bot started! Running..."

trap("INT"){ bot.quit }

bot.run
