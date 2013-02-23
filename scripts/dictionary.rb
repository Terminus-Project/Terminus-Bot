#
# Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#
# Copyright (C) 2010-2012 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

require 'rexml/document'
require 'htmlentities'

raise "dictionary script requires the http_client module" unless defined? MODULE_LOADED_HTTP

register 'Dictionary.com look-ups.'

helpers do
  def api_call opt = {}
    api_key = get_config :apikey, nil

    if api_key == nil
      reply "A dictionary.com API key must be set in the bot's configuration for this command to work."
      return  
    end

    opt[:vid] = api_key

    api = 'http://api-pub.dictionary.com/v001'

    Bot.http_get(URI(api), opt) do |http|
      yield (REXML::Document.new(http.response)).root
    end
  end

  def get_definition word, root, definitions
    coder   = HTMLEntities.new
    max     = get_config(:max, 1).to_i
    results = []

    root.elements.each do |entry|
      entry.elements.each do |foo|

        break if results.length >= max or results.length > definitions

        result = []

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
      reply "No results"
    else
      reply results
    end
  end
end

command 'define', 'Look up some of the possible definitions of a word.' do
  argc! 1

  api_call(:q => @params.first, :type => :define) do |root|

    definitions = root.elements["//dictionary"].attributes["totalresults"].to_i rescue 0

    if definitions == 0
      reply "No results"
    else
      get_definition @params.first, root, definitions
    end

  end
end

command 'spell', 'Suggest correct or alternate spellings of a word.' do
  argc! 1

  api_call(:q => @params.first, :type => :spelling) do |root|

    buf   = []
    coder = HTMLEntities.new

    buf << coder.decode(root.elements["//spelling/bestmatch/dictionary"].text) rescue ""

    root.elements["//spelling/suggestions/dictionaryitems"].elements.each do |e|
      buf << coder.decode(e.text)
    end

    if buf.empty?
      reply "No results"
    else
      reply"Best match: \02#{buf.shift}\02#{buf.empty? ? "" : " (Other matches: #{buf[0..10].join(", ")})"}"
    end
  end
end

command 'etymology', 'Look up the etymology of a word.' do
  argc! 1

  api_call(:site => :etymology, :q => @params.first) do |root|
    coder = HTMLEntities.new

    if ((root.elements['/results'].attributes['id'].to_s == "nothingfound") rescue false)
      reply "No results"
    else
      root = root.elements['/etymology']

      buf = "\02#{coder.decode root.elements['date'].text}\02: "
      buf << coder.decode(root.text).gsub(/<\/?(b|i)>/, "\02").gsub(/<.>/, '').gsub(/\s+/, " ")

      reply buf
    end
  end
end

#command 'thesaurus', 'Look up synonyms and antonyms of the given word.' do
#  argc! 1
#  api_call(msg, :type => :define, :site => :thesaurus, :q => params[0]) do |root|
#  end
#end

command 'slang', 'Look up possible meanings of a slang word.' do
  argc! 1

  api_call(:type => :define, :site => :slang, :q => @params.first) do |root|
    coder = HTMLEntities.new

    definitions = root.elements["//slang"].attributes["totalresults"].to_i rescue 0

    if definitions.zero?
      reply "No results"
    else
      get_definition @params.first, root, definitions
    end

  end
end

#command 'example', 'Find usage examples for the given word.' do
#  argc! 1
#  api_call(msg, :type => :example, :q => params[0]) do |root|
#  end
#end

command 'wotd', 'Fetch the Word of the Day on dictionary.com' do
  api_call(:type => :wotd) do |root|
    coder = HTMLEntities.new

    root = root.elements['/wordoftheday/entry']

    buf = "\02#{coder.decode(root.elements['word'].text)} "
    buf << "(#{coder.decode(root.elements['partofspeech'].text)}):\02 "
    buf << coder.decode(root.elements['shortdefinition'].text)

    reply buf
  end
end

#command 'synonyms', 'Find synonyms for the given word.' do
#  argc! 1
#end

command 'randword', 'Look up the definition of a random word.' do
  api_call(:type => :random) do |root|
    buf   = []
    coder = HTMLEntities.new

    word = coder.decode root.elements["//dictionary/random_entry"].text

    api_call(:q => word, :type => :define) do |root|
      definitions = root.elements["//dictionary"].attributes["totalresults"].to_i rescue 0

      if definitions == 0
        reply "No results"
      else
        get_definition word, root, definitions
      end
    end

  end
end

