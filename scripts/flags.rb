
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


def initialize
  register_script("Modify and query the script flag table.")

  # TODO: Allow channel operators to change flags for their own channels.

  register_command("enable",  :cmd_enable,  3, 4, nil, "Enable scripts in the given server and channel. Wildcards are supported. Parameters: server channel scripts")
  register_command("disable", :cmd_disable, 3, 4, nil, "Disable scripts in the given server and channel. Wildcards are supported. Parameters: server channel scripts")
  register_command("flags",   :cmd_flags,   3, 0, nil, "View flags for the given servers, channels, and scripts. Wildcards are supported. Parameters: server channel scripts")
end


def cmd_enable(msg, params)
  enabled = $bot.flags.enable(params[0], params[1], params[2])

  msg.reply("Enabled \02#{enabled}\02.")
end


def cmd_disable(msg, params)
  enabled = $bot.flags.disable(params[0], params[1], params[2])

  msg.reply("Disabled \02#{enabled}\02.")
end


def cmd_flags(msg, params)
  enabled, disabled, default = [], [], []

  $bot.flags.each_pair do |server, channels|
    next unless server.wildcard_match(params[0])

    channels.each_pair do |channel, scripts|
      next unless channel.wildcard_match(params[1])
      
      scripts.each_pair do |script, flag|
        next unless script.wildcard_match(params[2])

        case flag
        when -1
          disabled << script
        when 1
          enabled << script
        else
          default << script
        end

      end
    end
  end

  disabled.uniq!
  enabled.uniq!
  default.uniq!

  buf = ""
  buf << "\02Enabled (#{enabled.length}):\02 #{enabled.join(", ")}" unless enabled.empty?
  buf << " \02Disabled (#{disabled.length}):\02 #{disabled.join(", ")}" unless disabled.empty?
  buf << " \02Default (#{default.length}):\02 #{default.join(", ")}" unless default.empty?

  msg.reply(buf.empty? ? "No flags set." : buf)
end
      
