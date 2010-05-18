
  require 'thread'
  
  @@messageQueue = Queue.new
    Thread.new {
      $log.debug('outgoing') { "Thread started." }
      while true
        msg = @@messageQueue.pop
        $log.debug('outgoing') { "Sent: #{msg}" }
        $socket.puts(msg)
        sleep $config["Core"]["Bot"]["MessageDelay"]
      end
      $log.debug('outgoing') { "Thread stopped." }
    }

  def sendRaw(msg)
    @@messageQueue.push(msg)
  end

  def reply(message, reply)
    sendRaw("PRIVMSG #{message.replyTo} :#{reply}")
  end

  def sendPrivmsg(destination, message)
    sendRaw("PRIVMSG #{destination} :#{message}")
  end

  def sendNotice(destination, message)
    sendRaw("NOTICE #{destination} :#{message}")
  end
