
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


# If we're generating chains with random words, how
# many times do we try before giving up?
MAX_TRIES = 100

# Each word is a node. Each node contains a hash table of links to other nodes.
# A link is created each time one word follows another.
Node = Struct.new(:word, :links)

# Links are used to associate two nodes. The score is the number of times one
# word (represented by the target node) has followed the previous word (the
# parent node).
Link = Struct.new(:parent, :target, :score)


MARKOV_FILE = DATA_DIR + "markov.db"

def initialize
  register_script("Markov chain implementation that generates somewhat readable text.")

  register_event("PRIVMSG", :on_privmsg)

  register_command("markov", :cmd_markov, 1, 10, "Manage the Markov script. Parameters: ON|OFF|FREQUENCY percentage|CLEAR|LOAD filename|INFO|WRITE|NODE node|DELETE node")
  register_command("chain",  :cmd_chain,  0,  0, "Generate a random Markov chain. Parameters: [word [word]]")

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

    op = proc { create_chain(params.shift.downcase, false) }
    cb = proc { |chain| 
      if chain.empty?
        msg.reply("I was not able to create a chain with that seed.")
      else
        msg.reply(chain, false)
      end
    }

    EM.defer(op, cb)
  else
    msg.reply(random_chain, false)
  end
end

def cmd_markov(msg, params)
  arr = params[0].split
  here = msg.connection.name + "." + msg.destination

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

  return unless get_data(msg.connection.name + "." + msg.destination, false)

  return unless rand(100) <= get_data(:freq, 0)

  chain = create_chain(msg.stripped.split.sample.downcase)

  return if chain.empty?

  if chain =~ /\A\w+s\s/
    chain[0] = chain[0].downcase

    msg.reply("\01ACTION #{chain}\01", false)
  else
    msg.reply(chain, false)
  end
end


# Markov Stuff

def random_chain
  tries = 0
  chain = ""

  begin
    return nil if tries >= MAX_TRIES

    chain = create_chain
    tries += 1
  end while chain.empty?

  return chain
end


# Add a word pair to our data set.
#
# Create a link between nodes if one doesn't exist. If it does, just increment
# the link score by 1.
def add_pair(foo, bar)
  links = @nodes[foo].links

  unless links.has_key? bar
    links[bar] = Link.new(@nodes[foo], @nodes[bar], 1)
  else
    links[bar].score += 1
  end
end


# Process a line of text, adding usable words to the data set.
def parse_line(str)
  last_word = ""

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


# Get one word which could reasonably follow the given word based on the link
# scores in our data set.
def get_word(word)
  return nil unless @nodes.has_key? word

  # Get the top 20 most likely words.
  choices = @nodes[word].links.sort_by {|n, l| l.score }.shift(20)

  # Then return one of them, or nil if we don't have anything.
  return choices.empty? ? nil : choices.sample[0]
end


def create_chain(word = @nodes.keys.sample, random = true)
  buf = Array.new
  first = word.clone

  # If we were just given one word, let's find something that follows it.
  unless word.include? " "

    potentials = Array.new

    @nodes.keys.each do |key|
      if key.start_with? "#{word} " or key.end_with? " #{word}"

        potentials << key

      end
    end

    return "" if potentials.empty?

    first = potentials.sample.clone
    return "" if first == nil

    first = first.sub(/[!?.]/, '')
    word = first

  end

  $log.debug("markov.create_chain") { "Creating chain with seed: #{first}" }

  buf << word
  done = false

  25.times do
    word = get_word(word)

    tries = 0

    while word == nil
      if buf.empty?

        # We've popped off all our words! Looks like we can't build a chain
        # this word.
        return ""

      elsif buf.length == 1 and not random and tries < MAX_TRIES

        # We were asked for a chain starting with this word, so keep trying.
        word = get_word(first)
        tries += 1

      else

        # We couldn't make a chain with the last word. Try again with the
        # one before.
        word = get_word(buf.pop)

      end
    end

    word.split.each do |w|
      buf << w

      if w =~ /[?!.]\Z/
        done = true
        break
      end
    end

    break if done
  end
  
  return "" if buf.empty?

  chain = buf.join(" ")
  chain.capitalize!

  # Remove terminating punctuation from the first word.
  chain.sub!(/\A(\w+)[!?.]?/, '\1')

  # Capitalize "i"
  chain.gsub!(/\si('.+)?\s/, ' I\1 ')

  # Strip things that would need to be closed, like parens and quotation
  # marks.
  chain.gsub!(/[()"\[\]{}]/, "")

  if not chain =~ /[!?.]\Z/
    if chain =~ /[[:punct:]]\Z/
      chain[chain.length-1] = "."
    else
      chain << "."
    end
  end

  return chain
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
  while arr.length > 0
    file = arr.pop

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


def write_database
  fi = File.open(MARKOV_FILE, "w")

  @nodes.each do |word, node|
    fi << word << "\t"

    node.links.each do |n, l|
      fi << l.target.word << "\t"
      fi << l.score.to_s << "\t"
    end

    fi << "\n"
  end

  fi.close
end

def read_database
  return unless File.exists? MARKOV_FILE

  fi = File.open(MARKOV_FILE, "r")

  while line = fi.gets
    arr = line.split("\t")

    word = arr.shift

    @nodes[word] = Node.new(word, Hash.new) unless @nodes.has_key? word

    links = @nodes[word].links

    arr.each do |link|
      linked = arr.shift
      score  = arr.shift

      @nodes[linked] = Node.new(linked, Hash.new) unless @nodes.has_key? linked

      links[linked] = Link.new(@nodes[word], @nodes[linked], score.to_i)
    end

  end

  fi.close
end
