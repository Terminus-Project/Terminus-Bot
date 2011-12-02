
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


MARKOV_FILE = Terminus_Bot::DATA_DIR + "markov.db"

def initialize
  register_script("Markov chain implementation that generates somewhat readable text.")

  register_event("PRIVMSG", :on_privmsg)

  register_command("markov", :cmd_markov, 1, 10, "Manage the Markov script. Parameters: ON|OFF|FREQUENCY percentage|CLEAR|LOAD filename|INFO|GENERATE [word]")

  @nodes = Hash.new

  read_database
end

def die
  write_database

  unregister_script
  unregister_events
  unregister_commands
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
    if msg.private?
      msg.reply("This command may only be used in channels.")
      return
    end

    unless arr.length == 1
      msg.reply("Please provide only one parameter for the FREQUENCY action.")
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

    if arr.length == 0
      msg.reply("Please provide a list of files with the LOAD action.")
      return
    end

    msg.reply("Loading file(s). This may take a while.")

    Thread.pass

    read_files(msg, arr)

    msg.reply("Files loaded!")

  when "INFO"

    msg.reply("Items in data set: #{@nodes.length}")

  when "WRITE"

    begin
      write_database

      msg.reply("Database written.")
    rescue => e
      msg.reply("Failed to write database: #{e}")

      $log.error("markov.write_database") { e }
      $log.debug("markov.write_database") { e.backtrace }
    end

  when "GENERATE"

    if @nodes.length == 0
      msg.reply("There is no data from which to create a message.")
      return
    end

    chain = ""

    if arr.length >= 1
      chain = create_chain(arr.shift.downcase)
    else
      chain = random_chain
    end

    if chain.empty?
      msg.reply("I was unable to generate a chain.")
    else
      msg.reply(chain)
    end

  else

    msg.reply("Unknown action. Parameters: ON|OFF|FREQUENCY percentage|CLEAR|LOAD filename|INFO|GENERATE [word]")

  end

end


# Event Callbacks

def on_privmsg(msg)
  return if msg.private?

  if msg.text =~ /\01ACTION (.+)\01/
    parse_line($1)
  elsif msg.text.include? "\01"
    return
  else
    parse_line(msg.text)
  end

  return if msg.silent?

  return unless get_data(msg.connection.name + "." + msg.destination, false)

  return unless rand(100) <= get_data(:freq, 0)

  chain = create_chain(msg.text.split.sample.downcase)

  return if chain.empty?

  msg.reply(chain, false)
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

  str.split.each do |word|
    # We only want words that are alphanumeric. The rest likely won't make
    # for convincing text.
    next unless word =~ /\A[\w']+[[:punct:]]?\Z/
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


def create_chain(word = @nodes.keys.sample)
  buf = Array.new
  first = word.clone
  buf << word

  25.times do
    word = get_word(word)

    while word == nil
      if buf.length == 0

        # We've popped off all our words! Looks like we can't build a chain
        # this word.
        return ""

      else

        # We couldn't make a chain with the last word. Try again with the
        # one before.
        word = get_word(buf.pop)

      end
    end

    buf << word

    break if word =~ /[?!.]\Z/
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
      fi << l.target.word << " "
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
      link_arr = link.split(" ")

      @nodes[link_arr[0]] = Node.new(link_arr[0], Hash.new) unless @nodes.has_key? link_arr[0]

      links[link_arr[0]] = Link.new(@nodes[word], @nodes[link_arr[0]], link_arr[1].to_i)
    end

  end

  fi.close
end
