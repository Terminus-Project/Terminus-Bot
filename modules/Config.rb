
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

def initialize
  $bot.modHelp.registerModule("Config", "Commands for modifying bot configuration.")

  $bot.modHelp.registerCommand("Config", "config", "Show or set options. Separate options with dots (config ModuleConfig.SomeModule.SomeOption). Specify a value if you want to change or set an option.", "option value")
end

def cmd_config(message)
  return if message.speaker.adminLevel < 5

  if message.msgArr.length < 2
    reply(message, $bot.config.keys.join(", "))
  else
    configStr = "$bot.config"

    firstWord = true
    message.msgArr[1].split(".").each { |word|
      configStr += "[\"#{word}\"]"   
    }

    if message.msgArr.length < 3
      begin
        result = eval("#{configStr}.keys.join(\", \")")
      rescue
        begin
          result = eval("#{configStr}.to_s")
        rescue
          result = "That doesn't appear to be a valid option, or there is no way to represent that option with text."
        end
      end
      reply(message, result)
    else
      value = message.msgArr[2..(message.msgArr.length - 1)].join(" ")

      configStr += " = #{value}"
      eval(configStr)
      
      reply(message, "#{message.msgArr[1]} set to #{value}")
    end
    
  end
end

