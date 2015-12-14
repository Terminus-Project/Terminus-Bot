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

register "Provide on-protocol help for bot scripts and commands."

# "Show help for the given command or a list of all commands. Parameters: [command]"
# "Show a description of the given script or a list of all scripts. Parameters: [script]"

command 'help', 'Show command help. Syntax: help [command]' do
  if @params.empty?
    list_commands
    next
  end

  name = @params.shift.downcase

  unless Bot::Commands::COMMANDS.has_key? name
    raise "There is no help available for that command."
  end

  command = Bot::Commands::COMMANDS[name]

  reply command[:help]
end

command 'script', 'Show script info. Syntax: script [name]' do
  if @params.empty?
    list_scripts
    next
  end

  target = @params.shift.downcase

  script = Bot::Scripts.script_info.select do |s|
    s.name.downcase == target
  end.first

  if script.nil?
    raise "There is no information available on that script."
  else
    reply script.description
  end
end


helpers do
  def list_commands
    if get_config :multi_line, false
      s = Bot::Commands::COMMANDS.keys.sort.join(', ').chars.to_a
      line_length = get_config(:split_length, 400)
      cmd_ary = []
      until s.empty?
        cmd_ary <<  s.shift(line_length).join
      end
      cmd_ary.each do |cmd|
        reply cmd
      end
    else
      reply Bot::Commands::COMMANDS.keys.sort.join(', ')
    end
  end

  def list_scripts
    if get_config :multi_line, false
      s = Bot::Scripts.script_info.map{|s| s.name}.sort.join(', ').chars.to_a

      line_length = get_config(:split_length, 400)

      script_ary = []

      until s.empty?
        script_ary <<  s.shift(line_length).join
      end

      script_ary.each do |script|
        reply script
      end

    else
      reply Bot::Scripts.script_info.map{|s| s.name}.sort.join(', ')
    end
  end
end

# vim: set tabstop=2 expandtab:
