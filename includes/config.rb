
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


class Configuration < Hash

  attr :config

  FILE_NAME = "terminus-bot.conf"

  # Create a new configuration object.
  # Read the configuration file now.
  def initialize
    read_config
  end


  # Read the config file named by FILE_NAME.
  # Configuration is stored in @config, a hash table. Keys are
  # section names ([name] in the file). The values are more hash tables.
  # The key/value pair for those hash tables is the setting name and value.
  def read_config
    unless File.exists? FILE_NAME
      throw "No Config File"
    end

    $log.info("Configuration.read_config") { "Loading the configuration file." } 

    fi = File.open(FILE_NAME, "r")

    section = ""

    while line = fi.gets
      line.strip!

      # Skip comments and empty lines.
      next if line[0] == "#" or line.empty?

      # Section header!
      if line =~ /\[(.+)\]/
        section = $1.strip

        unless self.has_key? section
          self[section] = Hash.new
          $log.debug("Configuration.read_config") { "New config section: #{section}" } 
        end

      # A setting! Read it in.
      elsif line =~ /\A(.+)=(.+)\Z/
        
        if section.empty?
          throw "Congifuration before section declaration."
        end

        self[section][$1.strip] = $2.strip

      end

    end

    $log.debug("Configuration.read_config") { "Done loading the configuration file." } 

    fi.close
  end
end
