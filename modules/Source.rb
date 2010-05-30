
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

# This module is here for compliance with the AGPLv3 license!
# You CANNOT remove this module. If you do, you MUST provide
# some other means for the bot to provide a link to its source
# code. And if you customize the bot and release your own version,
# since it must ALSO be bound my the AGPLv3 license, you must change
# the link to the source here to a link to your source, or provide
# another means to get the link.
class Source

  def cmd_source(message)
    reply(message, "This software is licensed under the GNU Affero General Public License. You may acquire the source code at http://github.com/kabaka/Terminus-Bot or view the full license at http://www.gnu.org/licenses/agpl-3.0.html")
  end

end
