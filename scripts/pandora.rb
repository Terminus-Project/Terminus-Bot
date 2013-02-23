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

require "net/http"
require "uri"
require "strscan"
require "htmlentities"

register 'Provides an interface to Pandorabots.'

command 'pandora', 'Enable or disable Pandorabot interaction. Parameters: ON or OFF.' do
  half_op! and argc! 1

  if query?
    reply "You may only use this command in channels."
    next
  end

  case @params.first.upcase
  when "ON"

    store_data [@connection.name, @msg.destination], true
    reply "Pandorabot interaction enabled."

  when "OFF"

    store_data [@connection.name, @msg.destination], false
    reply "Pandorabot interaction disabled."

  else

    reply "Invalid choice. Must be ON or OFF."

  end
end

event :PRIVMSG do

  next unless get_data [@msg.connection.name, @msg.destination], false

  first = (@msg.text.split)[0]
  first = first[0..first.length-2].upcase

  next unless first == @connection.nick.upcase

  botid = get_config :botid, ""

  if botid.empty?
    raise "Bot ID is not set in the configuration. Pandora will not function."
  end

  get_reply botid, @msg.text[@connection.nick.length+2..@msg.text.length].chomp

end

helpers do

  def get_reply botid, str
    return if str.empty?

    custid = "#{@connection.name.to_s}/#{@msg.destination}"

    uri = URI("http://www.pandorabots.com/pandora/talk-xml")
    query_hash = {:custid => custid, :botid => botid, :input => str}

    Bot.http_post(uri, query_hash) do |response|
      begin
        $log.info('pandora.get_reply') { "Getting relpy with #{botid} for message: #{str}" }
        $log.info('pandora.get_reply') { response.content }

        response = response.content.gsub(/\n/, "").scan(/that>(.+)<\/that/)[0]

        if response == nil
          raise "empty pandora reply"
        end

        if response.kind_of? Array
          response = response.join " "
        end

        response = HTMLEntities.new.decode response.force_encoding('UTF-8')

        reply response.gsub(/<[^>]+>/, "").gsub(/\s+/, " ")
      rescue => e
        $log.error('pandora.get_reply') { "Error getting reply: #{e}" }
        reply "Error getting reply from Pandora: #{e}"
      end
    end
  end

end
