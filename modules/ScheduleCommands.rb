
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
  $bot.modHelp.registerModule("Scheduler", "Schedule commands to run at specified times or intervals.")

  $bot.modHelp.registerCommand("Scheduler", "scheduler add", "Schedule command to run at time. If repeat is given, repeat every 'time' seconds from epoch. If repeat is not given, run in 'time' seconds from now.", "[repeat] time command")
#  $bot.modHelp.registerCommand("Scheduler", "scheduler delete", "")
#  $bot.modHelp.registerCommand("Scheduler", "scheduler list", "")
end

def cmd_scheduler(message)

  case message.msgArr[1].downcase
    when "add"
      # scheduler add repeat? time command
      if message.msgArr.length < 3
        reply(message, "Usage: scheduler add [repeat] time command", true)
        return
      end

      repeat = message.msgArr[2].downcase == "repeat"

      if repeat
        time = message.msgArr[3]
        command = message.msgArr.clone()
        command.slice!(0, 4)
        command = command.join(" ")
      else
        time = (message.msgArr[2].to_i + Time.now.to_i)
        command = message.msgArr.clone()
        command.slice!(0, 3)
        command = command.join(" ")
      end

      fakeRaw = message.raw.match(/^([^:]+:)(.*)$/)[1]
      fakeRaw = fakeRaw + command
      cmdMsg = IRCMessage.new(fakeRaw, message.type)

      added = $scheduler.add("#{command} (#{message.speaker.nick})",
        Proc.new {
          message.bot.attemptHook(cmdMsg)
        },
        time.to_i,
        repeat) rescue "Failed to add item."
    
      reply(message, added.to_s, true)

    when "delete"


    when "list"


  end

end
