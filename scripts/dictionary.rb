
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


require 'rexml/document'
require 'htmlentities'

URL='http://api-pub.dictionary.com/v001'

def initialize
  raise "dictionary script requires the http module" unless defined? Bot.http_get

  register_script("Dictionary.com look-ups.")

  register_command("define",    :cmd_define,    1,  0, nil, "Look up some of the possible definitions of the given word.")
  register_command("spell",     :cmd_spell,     1,  0, nil, "Suggest correct or alternate spellings of the given word.")
  register_command("slang",     :cmd_slang,     1,  0, nil, "Look up possible meanings of the given slang word.")
  #register_command("example",   :cmd_example,   1,  0, nil, "Find usage examples for the given word.")
  #register_command("thesaurus", :cmd_thesaurus, 1,  0, nil, "Look up synonyms and antonyms of the given word.")
  #register_command("synonyms",  :cmd_synonyms,  1,  0, nil, "Find synonyms for the given word.")
  register_command("etymology", :cmd_etymology, 1,  0, nil, "Look up the etymology of a word on Dictionary.com")
  register_command("wotd",      :cmd_wotd,      0,  0, nil, "Fetch the Word of the Day on Dictionary.com")
  register_command("randword",  :cmd_random,    0,  0, nil, "Fetch a random word from Dictionary.com.")
end

def api_call(msg, opt = {})
  api_key = get_config(:apikey, nil)

  if api_key == nil
    msg.reply("A dictionary.com API key must be set in the bot's configuration for this command to work.")
    return  
  end

  # TODO: Build this as a URI object, not a string.
  url = "#{URL}?vid=" << URI.escape(api_key)

  opt.each do |k, v|
    url << "&" << k.to_s << "=" << URI.escape(v.to_s)
  end

  $log.debug("dictionary.api_call") { url }

  response = Bot.http_get(URI(url))

  return nil if response == nil

  return (REXML::Document.new(response[:response].body)).root
end

def get_definition(msg, word, root, definitions)
  coder = HTMLEntities.new
  max = get_config(:max, 1).to_i
  results = Array.new

  root.elements.each do |entry|
    entry.elements.each do |foo|

      break if results.length >= max or results.length > definitions
      
      result = Array.new

      head = "\02#{word}"
      head << " (#{coder.decode(foo.attributes["pos"])})" if foo.has_attributes? and foo.attributes["pos"] != nil
  
      foo.elements.each do |p|
        p.elements.each do |d|
          buf = (p.has_attributes? and p.attributes['pos'] != nil) ? "\02(#{coder.decode(p.attributes['pos'])})\02 " : ""

          text = d.has_text? ? d.text.strip : ""

          result << buf + coder.decode(d.text.strip) if text.length > 0
        end
      end

      unless result == nil
        buf = result.join("; ").gsub(/<\/?(b|i)>/, "\02").gsub(/<[^>]+>/, '').gsub(/\s+/, " ")

        results << head + ":\02 " + buf unless buf.empty?
      end

    end
  end

  if results.empty?
    msg.reply("No results")
    return
  end
    
  msg.reply(results)
end

def cmd_define(msg, params)
  root = api_call(msg, :q => params[0], :type => :define)

  definitions = root.elements["//dictionary"].attributes["totalresults"].to_i rescue 0

  if definitions == 0
    msg.reply("No results")
    return
  end

  get_definition(msg, params[0], root, definitions)
end

def cmd_spell(msg, params)
  root = api_call(msg, :q => params[0], :type => :spelling)

  buf = Array.new
  coder = HTMLEntities.new

  buf << coder.decode(root.elements["//spelling/bestmatch/dictionary"].text) rescue ""

  root.elements["//spelling/suggestions/dictionaryitems"].elements.each do |e|
    buf << coder.decode(e.text)
  end

  if buf.empty?
    msg.reply("No results")
  else
    msg.reply("Best match: \02#{buf.shift}\02#{buf.empty? ? "" : " (Other matches: #{buf[0..10].join(", ")})"}" )
  end
end

def cmd_etymology(msg, params)
  root = api_call(msg, :site => :etymology, :q => params[0])
  coder = HTMLEntities.new

  if ((root.elements['/results'].attributes['id'].to_s == "nothingfound") rescue false)
    msg.reply("No results")
    return
  end

  root = root.elements['/etymology']

  buf = "\02#{coder.decode(root.elements['date'].text)}\02: "
  buf << coder.decode(root.text).gsub(/<\/?(b|i)>/, "\02").gsub(/<.>/, '').gsub(/\s+/, " ")

  msg.reply(buf)
end

def cmd_thesaurus(msg, params)
  root = api_call(msg, :type => :define, :site => :thesaurus, :q => params[0])
end

def cmd_slang(msg, params)
  root = api_call(msg, :type => :define, :site => :slang, :q => params[0])
  coder = HTMLEntities.new

  definitions = root.elements["//slang"].attributes["totalresults"].to_i rescue 0

  if definitions == 0
    msg.reply("No results")
    return
  end

  get_definition(msg, params[0], root, definitions)
end

def cmd_example(msg, params)
  root = api_call(msg, :type => :example, :q => params[0])
end

def cmd_wotd(msg, params)
  root = api_call(msg, :type => :wotd)
  coder = HTMLEntities.new

  root = root.elements['/wordoftheday/entry']

  buf = "\02#{coder.decode(root.elements['word'].text)} "
  buf << "(#{coder.decode(root.elements['partofspeech'].text)}):\02 "
  buf << coder.decode(root.elements['shortdefinition'].text)

  msg.reply(buf)
end

def cmd_synonyms(msg, params)
end

def cmd_random(msg, param)
  root = api_call(msg, :type => :random)

  buf = Array.new
  coder = HTMLEntities.new

  word = coder.decode(root.elements["//dictionary/random_entry"].text)
  root = api_call(msg, :q => word, :type => :define)

  definitions = root.elements["//dictionary"].attributes["totalresults"].to_i rescue 0

  if definitions == 0
    msg.reply("No results")
    return
  end

  get_definition(msg, word, root, definitions)
end

