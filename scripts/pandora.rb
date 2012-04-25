
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
#


require "net/http"
require "uri"
require "strscan"
require "htmlentities"

PANDORA_URL = "http://www.pandorabots.com/pandora/talk-xml"

# TODO: Use config keys that aren't concatenated strings. :|

def initialize
  register_script("Provides an interface to Pandorabots.")

  register_command("pandora", :pandora, 1, 0, :half_op, "Enable or disable Pandorabot interaction. Parameters: ON or OFF.")

  register_event(:PRIVMSG, :on_message)
end

def pandora(msg, params)
  if msg.private?
    msg.reply("You may only use this command in channels.")
    return
  end

  case params[0].upcase
  when "ON"

    store_data([msg.connection.name, msg.destination], true)
    msg.reply("Pandorabot interaction enabled.")

  when "OFF"

    store_data([msg.connection.name, msg.destination], false)
    msg.reply("Pandorabot interaction disabled.")

  else
    msg.reply("Invalid choice. Must be ON or OFF.")
  end
end

def on_message(msg)
  return unless get_data([msg.connection.name, msg.destination], false)

  first = (msg.text.split)[0]
  first = first[0..first.length-2].upcase

  return unless first == msg.connection.nick.upcase

  botid = get_config(:botid, "")
  if botid.empty?
    msg.reply("Bot ID is not set in the configuration. Pandora will not function.")
    return
  end

  EM.defer(proc { 
    get_reply(botid, msg.text[msg.connection.nick.length+2..msg.text.length].chomp, msg)
  })
end

def get_reply(botid, str, msg)
  return if str.empty?

  begin
    $log.info('pandora.get_reply') { "Getting relpy with #{botid} for message: #{str}" }

    custid = msg.connection.name.to_s + "/" + msg.destination

    response = Net::HTTP.post_form(URI.parse(PANDORA_URL),
                                    :custid => custid,
                                    :botid => botid,
                                    :input => str)

    response = response.body.gsub(/\n/, "").scan(/that>(.+)<\/that/)[0]

    if response == nil
      msg.reply("Pandora gave me an empty reply.")
      return
    end

    if response.kind_of? Array
      response = response.join(" ")
    end

    response = HTMLEntities.new.decode(response.force_encoding('UTF-8'))

    msg.reply(response.gsub(/<[^>]+>/, "").gsub(/\s+/, " "))
  rescue => e
    $log.error('pandora.get_reply') { "Error getting reply: #{e}" }
    msg.reply("Error getting reply from Pandora: #{e}")
  end
end
