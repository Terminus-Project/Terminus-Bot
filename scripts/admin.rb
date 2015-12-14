#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

register 'Bot administration script.'

command 'quit', 'Kill the bot.' do
  level! 10

  EM.next_tick { @params.empty? ? Bot.quit : Bot.quit(@params.join ' ') }
end

command 'reconnect', 'Reconnect the specified connection.' do
  level! 10 and argc! 1

  name = @params.first.to_sym

  unless Bot::Connections.key? name
    raise "No such connection."
  end

  Bot::Connections[name].reconnect
  reply "Reconnecting."
end

command 'rehash', 'Reload the configuration file.' do
  level! 8

  Bot::Conf.read_config
  reply "Done reloading configuration."
end

command 'nick', 'Change the bot\'s nick for this connection.' do
  level! 7 and argc! 1

  send_nick @params.first
  reply "Nick changed to #{@params.first}"
end

command 'lib', 'Reload core files with stopping the bot. Warning: may produce undefined behavior.' do
  level! 9

  load_lib
  reply "Core files reloaded."
end

command 'reload', 'Reload one or more scripts.' do
  level! 9 and argc! 1

  EM.defer proc {
    arr, buf = @params.first.split, []

    arr.each do |script|

      begin
        Bot::Scripts.reload script
        buf << script

      rescue => e
        reply "Failed to reload \02#{script}\02: #{e}"
      end

    end

    reply "Reloaded script#{"s" if buf.length > 1} \02#{buf.join(", ")}\02" unless buf.empty?
  }
end

command 'unload', 'Unload one or more scripts.' do
  level! 9 and argc! 1

  EM.defer proc {
    arr, buf = @params.first.split, []

    arr.each do |script|

      begin
        Bot::Scripts.unload script
        buf << script

      rescue => e
        reply "Failed to unload \02#{script}\02: #{e}"
      end

    end

    reply "Unloaded script#{"s" if buf.length > 1} \02#{buf.join(", ")}\02" unless buf.empty?
  }
end

command 'load', 'Load the specified script.' do
  level! 9 and argc! 1

  EM.defer proc {
    begin
      Bot::Scripts.load_file "#{Bot::SCRIPTS_PATH}/#{@params.first}.rb"

      reply "Loaded script \02#{@params.first}\02"
    rescue => e
      reply "Failed to load \02#{@params.first}\02: #{e}"
    end
  }
end

# vim: set tabstop=2 expandtab:
