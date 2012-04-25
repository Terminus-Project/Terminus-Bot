#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2011 Terminus-Bot Development Team
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

module Bot
  class Database

    # The YAML library packaged with the current version of Ruby has a bug that
    # causes crashes or data loss when some unicode characters are parsed. Once
    # that is fixed, we can remove this.
    gem 'psych'

    require 'psych'

    FILENAME = "var/terminus-bot/data.db"

    # Read the database if it exists. Otherwise, write an empty database.
    def initialize
      @data = Hash.new

      if File.exists? FILENAME
        read_database
      else
        write_database
      end

      # Try to make sure we write our database before we exit.
      at_exit { write_database }
    end

    # Read the database into the @data structure. This should be
    # a hash table, since we initialize it as one and write it the first
    # time we run.
    def read_database
      @data = Psych.load(IO.read(FILENAME))
    end

    # Write @data converted to YAML to FILENAME.
    def write_database
      # TODO: Use the path from FILENAME.
      Dir.mkdir("var") unless Dir.exists? "var"
      Dir.mkdir("var/terminus-bot") unless Dir.exists? "var/terminus-bot"

      temp = "#{FILENAME}.tmp"

      $log.debug("Database.write_database") { "Marshaling data and writing to #{FILENAME}" }

      File.open(temp, "w") { |f| f.write(@data.to_yaml)}
      File.rename(temp, FILENAME)
    end

    # Implement a few Hash methods.
    # TODO: Find a way for this class to extend Hash and still play nice with
    #       Psych#load. Right now, it fails because load might not produce a Hash.

    def [](key)
      @data[key]
    end

    def []=(key, val)
      @data[key] = val
    end

    def delete(key)
      @data.delete(key)
    end

    def to_s
      @data.to_s
    end

    def has_key?(key)
      @data.has_key? key
    end
  end

  DB = Database.new
end
