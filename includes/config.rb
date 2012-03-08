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

  FILE_NAME = "terminus-bot.conf"

  # Create a new configuration object.
  # Read the configuration file now.
  def initialize
    read_config
  end


  # Read the config file named by FILE_NAME.
  def read_config
    throw "No Config File" unless File.exists? FILE_NAME

    $log.info("Configuration.read_config") { "Loading the configuration file." } 

    fi = File.open(FILE_NAME, 'r')

    root, parents, line_number = {}, [], 0

    current = self

    # Read in the whole file, skipping comments and stuff.
    while line = fi.gets
      line.strip!
      line_number += 1
        
      # Skip comments and empty lines.
      next if line[0] == "#" or line.empty?

      if line == "}"
        throw "Unexpected } on line #{line_number}" if parents.empty?

        current = parents.pop

        next
      end

      unless line.include? "="
        warn "Cannot parse line #{line_number}: #{line}"
        next
      end

      key, value = line.split("=", 2)

      key.strip!
      value.strip!
      
      if value == "{"

        if current.has_key? key
          $log.warn("Configuration.read_config") { "Duplicate configuration block #{key} on line #{line_number}" }
        else
          current[key] = {}
        end

        parents << current
        current = current[key]

        next
      end

      if current.has_key? key
        $log.warn("Configuration.read_config") { "Duplicate configuration option #{key} on line #{line_number}" }
      end

      # Handle a few data types.

      if value =~ /\A[0-9]+\Z/
        value = value.to_i

      elsif value.casecmp("true") == 0
        value = true

      elsif value.casecmp("false") == 0
        value = false

      end

      current[key] = value
    end

    $log.debug("Configuration.read_config") { "Done loading the configuration file." } 

    fi.close
  end
end

