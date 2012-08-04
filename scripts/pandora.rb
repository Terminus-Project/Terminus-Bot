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

PANDORA_URL = "http://www.pandorabots.com/pandora/talk-xml"

# TODO: Use config keys that aren't concatenated strings. :|

def initialize
  register_script "Provides an interface to Pandorabots."

  register_command "pandora", :pandora, 1, 0, :half_op, "Enable or disable Pandorabot interaction. Parameters: ON or OFF."

  register_event :PRIVMSG, :on_message
end

def pandora msg, params
  if msg.private?
    msg.reply "You may only use this command in channels."
    return
  end

  case params[0].upcase
  when "ON"

    store_data [msg.connection.name, msg.destination], true
    msg.reply "Pandorabot interaction enabled."

  when "OFF"

    store_data [msg.connection.name, msg.destination], false
    msg.reply "Pandorabot interaction disabled."

  else
    msg.reply "Invalid choice. Must be ON or OFF."
  end
end

def on_message msg
  return unless get_data [msg.connection.name, msg.destination], false

  first = (msg.text.split)[0]
  first = first[0..first.length-2].upcase

  return unless first == msg.connection.nick.upcase

  botid = get_config :botid, ""
  if botid.empty?
    msg.reply("Bot ID is not set in the configuration. Pandora will not function.")
    return
  end

  get_reply botid, msg.text[msg.connection.nick.length+2..msg.text.length].chomp, msg
end

def get_reply botid, str, msg
  return if str.empty?

  custid = "#{msg.connection.name.to_s}/#{msg.destination}"

  uri = URI(PANDORA_URL)
  query_hash = {:custid => custid, :botid => botid, :input => str}

  Bot.http_post(uri, query_hash) do |response|
    begin
      $log.info('pandora.get_reply') { "Getting relpy with #{botid} for message: #{str}" }

      response = response.content.gsub(/\n/, "").scan(/that>(.+)<\/that/)[0]

      if response == nil
        msg.reply "Pandora gave me an empty reply."
        raise "empty pandora reply"
      end

      if response.kind_of? Array
        response = response.join " "
      end

      response = HTMLEntities.new.decode response.force_encoding('UTF-8')

      msg.reply response.gsub(/<[^>]+>/, "").gsub(/\s+/, " ")
    rescue => e
      $log.error('pandora.get_reply') { "Error getting reply: #{e}" }
      msg.reply "Error getting reply from Pandora: #{e}"
    end
  end
end

