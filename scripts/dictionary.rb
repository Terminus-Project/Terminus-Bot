
#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
# Copyright (C) 2010 Terminus-Bot Development Team
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


require "uri"
require 'net/http'
require 'rexml/document'
require 'htmlentities'

# TODO: Move vid to config
URL='http://api-pub.dictionary.com/v001?vid=t9ebbvoze52a4cdf38oj1gmjltw2ul6nulz6gn5vt8'

def initialize
  register_script("dictionary", "Dictionary.com look-ups.")

  register_command("define", :cmd_define,   1,  0, "Look up some of the possible definitions of the given word.")
#  registerCommand("Dictionary", "spell", "Suggest correct or alternate spellings of the given word.", "word")
#  registerCommand("Dictionary", "thesaurus", "Look up synonyms and antonyms of the given word.", "word [part of speech]")
#  registerCommand("Dictionary", "slang", "Look up possible meanings of the given slang word.", "word [part of speech]")
#  registerCommand("Dictionary", "example", "Find usage examples for the given word.", "word [part of speech]")
#  registerCommand("Dictionary", "wotd", "Fetch the Word of the Day on Dictionary.com", "")
#  registerCommand("Dictionary", "synonyms", "Find synonyms for the given word.", "word [part of speech]")
#  registerCommand("Dictionary", "random", "Fetch a random word from Dictionary.com's extensive database.", "")
end

def cmd_define(msg, params)
  url = "#{URL}&type=define&q=#{URI.escape(params[0])}"

  body = Net::HTTP.get URI.parse(url)
  coder = HTMLEntities.new

  root = (REXML::Document.new(body)).root
  definitions = root.elements["//dictionary"].attributes["totalresults"] rescue 0

  if definitions == "0"
      reply(msg, "No results")
      return true
  end

  results = Array.new
  i = 0

  root.elements.each { |entry|
  # Entries
  
    entry.elements.each { |pos|
      # Parts of Speech

      break if i == 3 or i > Integer(definitions)
 
      result = "\02#{pos.attributes["pos"]}\02: " if pos.has_attributes? and pos.attributes["pos"] != nil
  
      pos.elements.each { |p|
        p.elements.each { |d|
          result << "#{coder.decode(d.text)}; " if d.has_text?
        }
      }
  
      unless result == nil
        result.gsub!(/<(b|i)>/, "\02")
        result.gsub!(/<\/(b|i)>/, "\02")
        result.gsub!(/<.>/, '')

        results << result
        i += 1
      end

    }
  
  }

  msg.reply(results)
end

def cmd_spell(msg)
end

def cmd_thesaurus(msg)
end

def cmd_slang(msg)
end

def cmd_example(msg)
end

def cmd_wotd(msg)
end

def cmd_synonyms(msg)
end

def cmd_random(msg)
end
