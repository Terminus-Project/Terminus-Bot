#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2013 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
# (http://terminus-bot.net/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#


module Bot
  class Database

    # XXX - see if this can be removed!

    # The YAML library packaged with the current version of Ruby has a bug that
    # causes crashes or data loss when some unicode characters are parsed. Once
    # that is fixed, we can remove this.
    gem 'psych'

    require 'psych'

    # TODO: use better relative path
    FILENAME = "var/terminus-bot/data.db"

    private_constant :FILENAME

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

    # Write database in YAML format.
    def write_database
      # TODO: Use the path from FILENAME.
      Dir.mkdir "var" unless Dir.exists? "var"
      Dir.mkdir "var/terminus-bot" unless Dir.exists? "var/terminus-bot"

      temp = "#{FILENAME}.tmp"

      $log.debug("Database.write_database") { "Marshaling data and writing to #{FILENAME}" }

      File.open(temp, "w") { |f| f.write(@data.to_yaml)}
      File.rename temp, FILENAME
    end

    # Implement a few Hash methods.
    # TODO: Find a way for this class to extend Hash and still play nice with
    #       Psych#load. Right now, it fails because load might not produce a Hash.


    # Retrieve database entry.
    # @param key [Object] entry to retrieve
    # @return [Object] database entry
    def [] key
      @data[key]
    end

    # Update database entry.
    # @param key [Object] key of object to update
    # @param val [Object] new value
    # @return [Object] set value
    def []= key, val
      @data[key] = val
    end

    # Delete a database entry.
    # @param key [Object] key to delete
    # @return [Object] deleted value
    def delete key
      @data.delete key
    end

    # Convert the database to a {String}.
    # @return [String]
    def to_s
      @data.to_s
    end

    # Check if the database has a key.
    # @param key [Object] key to check for
    # @return [Boolean] true if key exists, false if not
    def has_key? key
      @data.has_key? key
    end
  end

  DB ||= Database.new
end
# vim: set tabstop=2 expandtab:
