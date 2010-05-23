
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

class CTCP

  def bot_ctcpRequest(message)
    case message.msgArr[0]
      when "VERSION"
        sendNotice(message.speaker.nick, "#{1.chr}VERSION #{$config["Core"]["Bot"]["Version"]}#{1.chr}")
      when "URL"
          sendNotice(message.speaker.nick, "#{1.chr}URL #{$config["Core"]["Bot"]["URL"]}#{1.chr}")
      when "TIME"
        # implements rfc 822 section 5 as date-time
        sendNotice(message.speaker.nick, "#{1.chr}TIME #{DateTime.now.strftime("%d %m %y %H:%M:%S %z")}#{1.chr}")
      when "PING"
        sendNotice(message.speaker.nick, "#{1.chr}PING #{message.msgArr[1]}#{1.chr}")
      when "CLIENTINFO"
        sendNotice(message.speaker.nick, "#{1.chr}CLIENTINFO VERSION PING URL TIME#{1.chr}")
      else
        sendNotice(message.speaker.nick, "#{1.chr}ERRMSG #{message.msgArr[0]} QUERY UNKNOWN#{1.chr}")
    end
  end

end

$modules.push(CTCP.new)
