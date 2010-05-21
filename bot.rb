#!/usr/bin/ruby

require 'socket'
require 'logger'
require 'thread'
require 'timeout'

class TerminusBot

  def initialize(server, port, channels, configClass)
    $log.debug("pool") { "Thread pool init started." }
    @incomingQueue = Queue.new
    
    @threads = Array.new(5) {
      Thread.new {
        $log.debug("pool") { "Thread started." }
        while true
          request = @incomingQueue.pop

          attemptHook(request)
        end
      }
    }

    @channels = channels
    @configClass = configClass
    $network = Network.new()
    $socket = TCPSocket.open(server, port)
    raw "NICK " + $config["Core"]["Bot"]["Nickname"]
    raw "USER #{$config["Core"]["Bot"]["Ident"]} 0 * #{$config["Core"]["Bot"]["RealName"]}"
  end

  def raw(msg)
    $socket.puts(msg)
  end

  def run
    until $socket.eof? do
      msg = $socket.gets.chomp
      #puts msg

      # go ahead and handle server PING first
      if msg =~ /^PING (:.*)$/
        raw "PONG #{$1}"
        next
      end
      
      msg = msg.match(/^:?(.*)$/)[1]
      msgArr = msg.split(' ')

      case msgArr[1]
        when "PRIVMSG"
          content = msg.match(/^[^:]+:(.*)$/)[1]
          message = IRCMessage.new(msg, msgArr[2], content, msgArr[0])

          if message.message.include? 1.chr
            #CTCP
            
            ctcpData = msg.match(/#{1.chr}([^ ]+) ?(.*)#{1.chr}/)

            case ctcpData[1]
              when "ACTION"
                # will fire an event soon!
              when "VERSION"
                sendNotice(message.speaker.nick, "#{1.chr}VERSION #{$config["Core"]["Bot"]["Version"]}#{1.chr}")
              when "URL"
                sendNotice(message.speaker.nick, "#{1.chr}URL #{$config["Core"]["Bot"]["URL"]}#{1.chr}")
              #when "TIME"
              #needs to implement rfc 822 section 5
              #  sendNotice(message.speaker.nick, "#{1.chr}TIME #{}#{1.chr}")
              when "PING"
                sendNotice(message.speaker.nick, "#{1.chr}PING #{ctcpData[2]}#{1.chr}")
              when "CLIENTINFO"
                sendNotice(message.speaker.nick, "#{1.chr}CLIENTINFO VERSION PING URL #{1.chr}")
              else
                sendNotice(message.speaker.nick, "#{1.chr}ERRMSG #{ctcpData[1]} DEPRECATED#{1.chr}")
              end
            next
          end

          #puts "[#{message.timestamp}] <#{message.speaker.nick}:#{message.destination}> #{message.message}"
          
          #attemptHook(message.msgArr[0], message)
          work(message)

        when "NOTICE"
          content = msg.match(/^[^:]+:(.*)$/)[1]
          message = IRCMessage.new(msg, msgArr[2], content, msgArr[0])
          work(message)

          #puts "[#{message.timestamp}] --#{message.speaker.nick}:#{message.destination}-- #{message.message}"

        # And now, on to the numerical codes.
        # I don't have all of these on here, but it would
        # be trivial to add more. What I do have here is
        # mostly for logging and debugging, anyway.
        when "004"
          $network.currentServer = msgArr[3]
          $network.serverSoftware = msgArr[4]
        when "005"
          msgArr.each { |param|
            paramArr = param.split("=")
            case paramArr[0]
              when "NETWORK"
                $network.name = paramArr[1]
              when "MAXCHANNELS"
                $network.maxChannels = paramArr[1]
              when "CHANNELLEN"
                $network.maxChannelNameLength = paramArr[1]
              when "TOPICLEN"
                $network.maxTopicLength = paramArr[1]
              when "KICKLEN"
                $network.maxKickLength = paramArr[1]
              when "AWAYLEN"
                $network.maxAwayLength = paramArr[1]
              when "MAXTARGETS"
                $network.maxTargets = paramArr[1]
              when "MODES"
                $network.maxModes = paramArr[1]
              when "CHANTYPES"
                $network.channelTypes = paramArr[1]
              when "CHANMODES"
                $network.channelModes = paramArr[1]
              when "CASEMAPPING"
                $network.caseMapping = paramArr[1]
              when "PREFIX"
                $network.prefixes = paramArr[1]
              when "MAXLIST"
                maxListArrs = paramArr[1].split(",")
                maxListArrs.each { |maxListArr|
                  maxListArr = maxListArr.split(":")                  
                  if maxListArr[0] == "b"
                    $network.maxBans = maxListArr[1]
                  elsif maxListArr[0] == "e"
                    $network.maxExempts = maxListArr[1]
                  elsif maxListArr[0] == "I"
                    $network.maxInviteExempts = maxListArr[1]
                  else
                    $log.warn('parser') { "Invalid MAXLIST parameter: #{maxListArr.join(":")}" }
                  end
                }
          
            end
          }
        when "JOIN" #We're joining something!
          channel = msg.match(/:(.*)/)[1]
          $log.debug('parser') { "Joining: #{channel}" }

          # If this channel isn't in config, put it in.

          $config["Core"]["Server"]["Channels"] << channel unless $config["Core"]["Server"]["Channels"].include? channel
        when "NICK" #We're changing nicks!
          nick = msg.match(/:(.*)/)[1]
          $log.debug('parser') { "Nick changed: #{nick}" }

          $config["Core"]["Bot"]["Nickname"] = nick

          
=begin
        when "324" #channel modes
        when "331" #no topic
        when "332" #channel topic
        when "341" #invite success
        when "342" #summoning
        when "346" #invite mask data
        when "347" #end of invite masks
        when "348" #exception mask reply
        when "349" #end of exception masks
        when "351" #server version reply
        when "352" #who reply
        when "315" #end of who reply
        when "364" #links
        when "365" #end of links
        when "367" #ban list
        when "368" #end of ban list
        when "375" #motd start
        when "381" #oper success
        when "382" #rehashing
        when "391" #server time
        when "219" #end of stats
        when "242" #stats uptime
        when "243" #stats oline
        when "221" #own mode reply
        when "256" #admin info 1
        when "257" #admin info 2
        when "258" #admin info 3
        when "259" #admin info 4
        when "263" #command dropped, try again
        when "401" #no suck nick/channel
        when "402" #no such server
        when "403" #no such channel
        when "404" #cannot send to channel
        when "405" #too many channels
        when "406" #was no such nick
        when "407" #too many targets
        when "412" #no text to send
        when "415" #bad server/host mask
        when "421" #unknown command
        when "423" #no admin info
        when "431" #no nick given
        when "432" #erroneous nick (on change)
        when "433" #nick in use (on change)
        when "436" #nick collision
        when "437" #resource unavailable
        when "441" #nick isn't on channel
        when "442" #you're not on that channel
        when "443" #user already on channel (after invite)
        when "444" #user not logged in (after summon)
        when "445" #summon disabled
        when "446" #user disabled
        when "451" #not registered
        when "461" #not enough params
        when "462" #already registered, illegal command
        when "463" #no oper for host
        when "464" #password incorrect
        when "465" #you are banned from the server
        when "466" #you are about to be banned from server
        when "467" #key already set
        when "471" #cannot join, at +l
        when "472" #unknown mode char for channel
        when "473" #cannot join, +i
        when "474" #cannot join, +b
        when "475" #cannot join, wrong key
        when "476" #bad channel mask
        when "477" #chan doesn't support modes
        when "478" #channel ban list full
        when "481" #no oper privileges
        when "482" #no chan oper privileges
        when "483" #cannot kill a server
        when "484" #connection restricted
        when "485" #you are not channel creator
        when "491" #no o-lines for your host
        when "501" #unknown mode flag
        when "502" #cannot change mode for other users
=end
        when "353" #names list
          names = msg.match(/.*:(.*)/)
          names = names[1].split(" ")
          names.each { |name|
            # these will go into a channel object once that's ready
          }
        when "366" #end of names list

        when "376" #end of motd
          $log.debug('parser') { "End of MOTD." }
          raw "JOIN #{$config["Core"]["Server"]["Channels"].join(",")}"
          
        when "422" #motd not found
          $log.debug('parser') { "MOTD not found." }
          raw "JOIN #{$config["Core"]["Server"]["Channels"].join(",")}"

	#else
        #  $log.debug('parser') { "Unknown message type: #{msg}" }
      end
    end

    $log.info('exit') { "Socket closed, starting exit procedure." }

    @configClass.saveConfig
    
    $log.info('exit') { "Exit procedures complete. Exiting!" }
    $log.close

    exit
  end

  def work(message)
    @incomingQueue.push(message)
  end

  def quit(quitMessage = $config["Core"]["Bot"]["QuitMessage"])
    raw 'QUIT :' + quitMessage
  end

  def attemptHook(msg)

    # First, we're going to fire command hooks. The first word of the
    # message is used as the command name. If the message is sent in
    # a channel, the command prefix must be used, and is extracted
    # via regular expression.
    #
    # The header of the function in the module must be:
    #
    #  cmd_name(message)
    #
    #   "name" is the word that will trigger the command. 
    #   "message" is an IRCMessage object that represents the message
    #     that triggered the command.

    cmd = msg.msgArr[0].downcase

    if cmd =~ /\A#{Regexp.escape $config["Core"]["Bot"]["CommandPrefix"]}(.*)/
      cmd = $1
      cmd.gsub!(/[^a-z]/, "_")
      fireHooks("cmd_#{cmd}", msg)
    elsif msg.type == PRIVATE
      cmd.gsub!(/[^a-z]/, "_")
      fireHooks("cmd_#{cmd}", msg)
    end

    # Now that we're done with those, we'll fire generic events.
    # These will be functions that fire every single time a message
    # is received. No trigger word is required, and no command prefix
    # will be checked or removed.
    #
    # Modules should use these events to perform their own parsing on
    # messages.
    #
    # The function header in the module should be:
    #
    #   bot_onMesageReceived(message)
    #
    #   "message" is an IRCMessage object which represents the message
    #     that fired the event.
    
    fireHooks("bot_onMessageReceived", msg)
      
  end

  def fireHooks(cmd, msg)
      $modules.each do |m|
         #$log.debug('bot') { "attemptHook #{m} -> #{cmd}" }
         m.send(cmd,msg) if m.respond_to?(cmd)
      end
  end
end

def enumerateIncludes(dir)
  $log.debug('init-enum') { "Enumerating files in #{dir}" }
  Dir.foreach(dir) { |f|
    unless f =~ /\A\.\.?\Z/
      f = dir + '/' + f
      if File.directory? f
        enumerateIncludes(f)
      elsif File.exists? f
        load f
      end
    end
  }

end

$log = Logger.new('logs/system.log', 'weekly');

$log.info('init') { 'Terminus-Bot is now starting.' }


$log.debug('init') { 'Loading core bot files.' }
puts "Loading bot core..."
enumerateIncludes("./includes/")

$log.debug('init') { 'Loading configuration.' }
puts "Loading configuration..."
load "config.rb"

configClass = Config.new

$log.debug('init') { 'Loading modules.' }
puts "Loading modules..."
$modules = Array.new()
Dir.foreach("modules") { |f| load "./modules/#{f}" unless f.match(/^\.+$/) }

$log.debug('init') { 'Firing off the bot.' }
puts "Done. Establishing IRC connection..."
bot = TerminusBot.new(
  $config["Core"]["Server"]["Address"],
  $config["Core"]["Server"]["Port"],
  $config["Core"]["Server"]["Channels"],
  configClass)

$log.info('init') { 'Bot started! Now running.' }
puts "Terminus-Bot started! Running..."

trap("INT"){ bot.quit }

bot.run


