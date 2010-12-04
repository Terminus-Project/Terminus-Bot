
#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

require "net/http"
require "uri"
require "json"

def initialize
  registerModule("Translator", "Translate text using Google Translate.")

  registerCommand("Translator", "translate", "Translate text with Google Translate. Languages must be specified with their two-character abbreviations.", "from to text")
end

#curl -e http://www.my-ajax-site.com \
#        'http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=hello%20world&langpair=en%7Cit'
#

def cmd_translate(message)
  if message.msgArr.length < 3
    reply(message, "Usage: #{UNDERLINE}from#{NORMAL} #{UNDERLINE}to#{NORMAL} #{UNDERLINE}text#{NORMAL}")
  else
    translation = getTranslation(message.msgArr[2], message.msgArr[1], message.msgArr[3..message.msgArr.length-1].join(" "))
    reply(message, translation, false)
  end
end


def getTranslation(to, from, text)
  $log.debug('translate') { "Translating text from #{from} to #{to}." }

  pair = URI.escape("#{from}|#{to}")
  text = URI.escape(text)
  url = "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=#{text}&langpair=#{pair}"

  page = Net::HTTP.get URI.parse(url)

  page = JSON.parse(page)
  # {"responseData"=>{"translatedText"=>"Ini adalah ujian."}, "responseDetails"=>nil, "responseStatus"=>200}
  if page["responseStatus"] != 200
    return "There was a problem with the translation: #{page["responseDetails"]}"
  else
    return page["responseData"]["translatedText"]
  end
end
