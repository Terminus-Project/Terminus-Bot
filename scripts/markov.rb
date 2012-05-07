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

# TODO: Fix the node implementation. We should be able to use an arbitrary
#       number of words for each node, and they should be stored separately.

# Each word is a node. Each node contains a hash table of links to other nodes.
# A link is created each time one word follows another.
Node = Struct.new(:word, :links)

# Links are used to associate two nodes. The score is the number of times one
# word (represented by the target node) has followed the previous word (the
# parent node).
Link = Struct.new(:parent, :target, :score)


MARKOV_FILE = "var/terminus-bot/markov.db"

def initialize
  register_script("Markov chain implementation that generates somewhat readable text.")

  register_event(:PRIVMSG, :on_privmsg)

  register_command("markov", :cmd_markov, 1, 10, nil, "Manage the Markov script. Parameters: ON|OFF|FREQUENCY percentage|CLEAR|LOAD filename|INFO|WRITE|NODE node|DELETE node")
  register_command("chain",  :cmd_chain,  0,  0, nil, "Generate a random Markov chain. Parameters: [word [word]]")

  @nodes = Hash.new

  read_database
end

def die
  write_database
end

def cmd_chain(msg, params)

  if @nodes.empty?
    msg.reply("My Markov database is empty, so I can't generate any chains.")
    return
  end

  if params.length == 1

    if params[0].count(" ") > 1
      msg.reply("Chain seeds can contain two or less words.")
      return
    end

    build_chain(params[0].dup) do |chain|
      msg.reply(chain, false)
    end
  else
    build_chain do |chain|
      msg.reply(chain, false)
    end
  end
end

def cmd_markov(msg, params)
  arr = params[0].split
  here = [msg.connection.name, msg.destination]

  case arr.shift.upcase

  when "ON"
    if msg.private?
      msg.reply("This command may only be used in channels.")
      return
    end

    store_data(here, true)

    msg.reply("Markov interaction enabled for this channel.")

  when "OFF"
    if msg.private?
      msg.reply("This command may only be used in channels.")
      return
    end

    store_data(here, false)

    msg.reply("Markov interaction disabled for this channel.")

  when "FREQUENCY"
    unless arr.length == 1
      msg.reply("Frequency: #{get_data(:freq, 0)}")
      return
    end

    chance = arr[0].to_i

    if chance <= 0 or chance > 100
      msg.reply("The frequency must be a positive whole number greater than 0 and less than or equal to 100.")
      return
    end

    store_data(:freq, chance)

    msg.reply("Frequency changed to #{chance}")

  when "CLEAR"

    @nodes.clear

    msg.reply("Working data set has been cleared.")

  when "LOAD"

    if arr.empty?
      msg.reply("Please provide a list of files with the LOAD action.")
      return
    end

    msg.reply("Loading file(s). This may take a while.")

    # TODO: Kill this defer call.
    op = proc {
      read_files(msg, arr)
      msg.reply("Files loaded!") 
    }

    EM.defer(op)

  when "INFO"

    links = 0
    bytes = 0

    @nodes.each do |word, node|
       links += node.links.length

       bytes += word.bytesize
    end

    bytes /= 1024.0

    msg.reply(sprintf "Items in data set: \02%d\02 (%4.4f KiB text). Word associations: \02%d\02.",
              @nodes.length, bytes, links)

  when "WRITE"

    # TODO: Kill this defer call.
    op = proc {
      begin
        write_database
      rescue => e
        msg.reply("Failed to write database: #{e}")

        $log.error("markov.write_database") { e }
        $log.debug("markov.write_database") { e.backtrace }
      end

      msg.reply("Database written.")
    }

    EM.defer(op)

  when "NODE"

    if arr.empty? or arr.length > 2
      msg.reply("Please provide one or two words.")
      return
    end

    links = 0

    if arr.length == 2
      input = arr.join(" ")

      unless @nodes.has_key? input
        msg.reply("No such node.")
        return
      end

      links = @nodes[input].links.length
    else

      input = arr.shift

      @nodes.each_pair do |word, node|
        if word.start_with? "#{input} " or word.end_with? " #{input}"
          links += node.links.length
        end
      end

    end

    msg.reply("\02Links:\02 #{links}")

  when "DELETE"

    if arr.length != 2
      msg.reply("Please provide a two-word node.")
      return
    end

    input = arr.join(" ")

    unless @nodes.has_key? input
      msg.reply("No such node.")
      return
    end

    @nodes.delete(input)

    msg.reply("Markov node \02#{input}\02 deleted.")

  else

    msg.reply("Unknown action. Parameters: ON|OFF|FREQUENCY percentage|CLEAR|LOAD filename|INFO|WRITE|NODE node|DELETE node")

  end

end


# Event Callbacks

def on_privmsg(msg)
  return if msg.private?

  if msg.text =~ /\01ACTION (.+)\01/
    parse_line(msg.strip($1))
  elsif msg.text.include? "\01"
    return
  else
    parse_line(msg.stripped)
  end

  return if msg.silent?

  return unless get_data([msg.connection.name, msg.destination], false)

  return unless rand(100) <= get_data(:freq, 0)

  build_chain(msg.stripped.split.sample.downcase, false) do |chain|
    next if chain.empty?

    if chain =~ /\A\w+s\s/
      chain[0] = chain[0].downcase

      msg.reply("\01ACTION #{chain}\01", false)
    else
      msg.reply(chain, false)
    end
  end
end


# Markov Stuff

# Add a word pair to our data set or increment a link score.
def add_pair(foo, bar)
  links = @nodes[foo].links

  links[bar] ||= Link.new(@nodes[foo], @nodes[bar], 1)
  links[bar].score += 1
end


# Process a line of text, adding usable words to the data set.
def parse_line(str)
  last_word = ""

  # TODO: This is wrong. Fix it.
  str.scan(/[\w'-]+[[:punct:]]?\s+[\w'-]+[[:punct:]]?/).each do |word|
    word.downcase!

    # Skip empty words and links. This could use some improvement.
    next if word.empty? or word.start_with? "http"

    # Add this to our nodes data set if it's not already there.
    @nodes[word] = Node.new(word, Hash.new) unless @nodes.has_key? word

    add_pair(last_word, word) unless last_word.empty?
    last_word = word
  end
end


def build_chain(word = @nodes.keys.sample.dup, requested = true)
  word = find_pair_with_word(word) unless word.include? " "

  return if word == nil and not requested

  word.gsub!(/[!?.]/, '')

  chain = chainer(word)

  if chain.empty?
    yield "I was not able to create a chain with that seed."
    return
  end

    # Remove terminating punctuation from the first word.
  chain.sub!(/\A(\w+)[!?.]?/, '\1')

  # Capitalize "i"
  chain.gsub!(/\si('.+)?\s/, ' I\1 ')

  # Strip things that would need to be closed, like parens and quotation
  # marks.
  chain.gsub!(/[()"\[\]{}]/, "")

  if not chain =~ /[!?.]\Z/
    if chain =~ /[[:punct:]]\Z/
      chain[-1] = "."
    else
      chain << "."
    end
  end

  yield chain.capitalize!
end

def find_pair_with_word(word)
  potentials = @nodes.keys.select do |key|
    key.start_with? "#{word} " or key.end_with? " #{word}"
  end

  potentials.empty? ? nil : potentials.sample.dup
end

# Get one word which could reasonably follow the given word based on the link
# scores in our data set.
def get_word(word)
  return nil unless @nodes.has_key? word

  # Get the top 20 most likely words.
  choices = @nodes[word].links.sort_by {|n, l| l.score }.shift(20)

  # Then return one of them, or nil if we don't have anything.
  choices.empty? ? nil : choices.sample[0]
end

def chainer(word, random = true, depth = 0)
  return "" if depth == 25

  buf, done = "", false
  result = get_word word

  if result == nil
    if depth.zero?
      return word.dup
    else
      return ""
    end
  end

  result.split.each_with_index do |w, i|
    buf << w

    if w =~ /[?!.]\Z/
      done = true
      break
    end

    buf << " " if i.zero?
  end

  unless done
    unless (next_word = chainer(buf, random, depth + 1)).empty?
      buf << " " << next_word
    end
  end

  if depth.zero?
    "#{word} #{buf}"
  else
    buf
  end
end


# Load a plain text file into our data set.
def load_file(filename)
  File.open(filename, "r") do |fi|
    while line = fi.gets

      # stupid encoding errors
      # just catch them and skip the bad line
      # TODO: do this correctly
      begin
        parse_line(line)
      rescue
        next
      end

    end
  end
end


# Read a WeeChat log file into our data set. Only channel messages and actions
# are used.
def load_weechat_log(filename)
  File.open(filename, "r") do |fi|
    while line = fi.gets

      # stupid encoding errors
      # just catch them and skip the bad line
      # TODO: do this correctly
      begin
        if line =~ /\A(.+)\t(.+)\t(.+)\Z/
          text = $3
          next if $2 =~ /<?-->?/ or text == nil

          parse_line(text)
        end
      rescue
        next
      end

    end
  end
end

def read_files(msg, arr)
  while file = arr.shift

    unless File.exists? file
      msg.reply("File #{file} does not exist. Skipping.")
      next
    end

    if file =~ /\.weechatlog\Z/
      load_weechat_log(file)
    else
      load_file(file)
    end
      
  end
end


# TODO: Speed these up. Somehow.

def write_database
  $log.info("Markov.write_database") { "If the database is large, this will take a while." }

  temp = "%s.tmp" % MARKOV_FILE
  fi = File.open(temp, "w")

  @nodes.each do |word, node|
    fi << "%s\t" % word

    node.links.each do |n, l|
      fi << "%s\t%d\t" % [l.target.word, l.score]
    end

    fi << "\n"
  end

  fi.close

  File.rename(temp, MARKOV_FILE)

  $log.info("Markov.write_database") { "Done writing database." }
end

def read_database
  return unless File.exists? MARKOV_FILE

  $log.info("Markov.read_database") { "If the database is large, this will take a while." }

  fi = File.open(MARKOV_FILE, "r")

  while line = fi.gets
    arr = line.force_encoding('UTF-8').chomp.split("\t")

    word = arr.shift

    if word == nil or word.empty?
      $log.warn("Markov.read_database") { "Skipping invalid database entry." }
      next
    end

    @nodes[word] ||= Node.new(word, Hash.new)

    links = @nodes[word].links

    until arr.empty?
      linked = arr.shift
      score  = arr.shift.to_i

      if score == 0 or linked == nil or linked.empty?
        $log.warn("Markov.read_database") { "Skipping invalid database entry." }
        next
      end
 
      @nodes[linked] ||= Node.new(linked, Hash.new)

      links[linked] = Link.new(@nodes[word], @nodes[linked], score)
    end

  end

  fi.close

  $log.info("Markov.read_database") { "Done loading database." }
end
