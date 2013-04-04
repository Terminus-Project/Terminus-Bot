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

module Bot
  module Commands

    unless defined? COMMANDS
      Bot::Events.create :PRIVMSG, self, :on_privmsg

      COMMANDS = {}
      ALIASES  = {}
    end

    def self.on_privmsg msg
      prefix = Regexp.escape Bot::Conf[:core][:prefix]

      match = msg.text.match(/^(?<prefix>#{prefix})?(?<command>[^ ]+)( (?<params>.+))?/i)

      return unless msg.query? or match[:prefix]

      cmd_str = match[:command].downcase

      if ALIASES.has_key? cmd_str
        cmd_str = ALIASES[cmd_str]
      end

      return unless COMMANDS.has_key? cmd_str
        
      command = COMMANDS[cmd_str]

      return unless Bot::Flags.permit_message? command[:owner], msg

      level = msg.connection.users.get_level msg

      $log.debug("CommandManager.on_privmsg") { "Match for command #{cmd_str} in #{command[:owner]}" }

      Command.run command[:owner], msg, cmd_str, match[:params], &command[:block]
    end

    def self.create owner, cmd, help, &blk
      cmd.downcase!

      if COMMANDS.has_key? cmd
        raise "attempted to register duplicate command #{cmd} for #{owner.class.name}"
      end

      if ALIASES.has_key? cmd
        raise "attempted to register command #{cmd} for #{owner.class.name} but an alias by that name already exists"
      end

      $log.debug("CommandManager.create") { "Creating command: #{cmd}" }

      COMMANDS[cmd] = {:owner => owner, :block => blk, :help => help}
    end

    def self.create_alias cmd, target
      cmd.downcase!
      target.downcase!

      if COMMANDS.has_key? cmd
        raise "attempted to register alias #{cmd} for #{owner.class.name} but a command by that name already exists"
      end

      if ALIASES.has_key? cmd
        raise "attempted to register duplicate alias #{cmd} for #{owner.class.name}"
      end

      unless COMMANDS.has_key? target
        raise "target command #{target} does not exist"
      end

      $log.debug("CommandManager.create_alias") { "Creating alias: #{cmd}" }

      ALIASES[cmd] = target
    end

    def self.delete cmd
      cmd.downcase!

      raise "attemped to delete non-existent command #{cmd}" unless COMMANDS.has_key? cmd

      $log.debug("CommandManager.delete") { "Deleting command: #{cmd}" }

      delete_aliases_for target

      COMMANDS.delete cmd
    end

    def delete_alias cmd
      cmd.downcase!

      raise "attempted to delete non-existent alias #{cmd}" unless ALIASES.has_key? cmd

      $log.debug("CommandManager.delete_alias") { "Deleting alias: #{cmd}" }

      ALIASES.delete cmd
    end

    def self.delete_aliases_for target
      ALIASES.reject! do |a, t|
        t == target
      end

      true
    end

    def self.delete_for owner
      $log.debug("CommandManager.delete_for") { "Unregistering all commands for #{owner.class.name}" }

      COMMANDS.reject! do |n,c| 
        c[:owner] == owner and delete_aliases_for n
      end
    end

  end

end
