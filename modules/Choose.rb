
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
  registerModule("Choose", "Let the bot decide for you.")

end

def bot_privmsg(message)
  return unless message.msgArr[0] == $bot.config["Prefix"]
  return unless message.message.end_with? "?"
  
  choices = message.message.split(" or ")


  if choices.length == 1
    answer = rand(2) == 1 ? "Yes" : "No"
  else
    # chop off the prefix and space
    choices[0] = choices[0][2..choices[0].length-1]

    #chop off the question mark
    choices[choices.length-1] = choices[choices.length-1][0..choices[choices.length-1].length-2]

    answer = choices[rand(choices.length)]
  end

  message.reply(answer, true)
end
