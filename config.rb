#
#    Terminus-Bot: An IRC bot to solve all of the problems with IRC bots.
#    Copyright (C) 2010  Terminus-Bot Development Team
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Config

  attr :config

  require 'yaml'
  require 'fileutils'
  require 'digest/md5'

  def initialize(configFile = "configuration")
    @configFile = configFile

    if File.zero? configFile or not File.exists? configFile
      # The configuration file doesn't exist! Let's ask the user
      # for some things so we can generate one.
        
      puts "\nIt looks like this is your first time using Terminus-Bot!"
      puts "To start, we'll need to ask some simple questions.\n"

      puts "What is the host name or IP address of the network to which the bot should connect?"
      serverAddress = gets.chomp

      puts "What is the port to which the bot should connect? (6667 is probably fine.)"
      serverPort = gets.chomp
      serverPort = 6667 if serverPort.empty?

      puts "What nick name should the bot use?"
      botNick = gets.chomp

      puts "What channels should the bot join on connect? Separate these by comma!"
      channels = gets.chomp

      puts "What is the ident name (nick!ident@host) the bot should try to use?"
      ident = gets.chomp

      puts "What is the \"real name\" the bot should use?"
      realname = gets.chomp

      puts "Commands are prefixed with one or more characters, such as '!' or 'Terminus-Bot:'. What command prefix do you want to use?"
      cmdPrefix = gets.chomp

      puts "That is all we need to get the bot connected and running! But, we still need a few more things."

      puts "Specify a user name to use for authentication with the bot. This does not have to be your nick name."
      adminUser = gets.chomp

      puts "And lastly, what password do you want to use when you log in?"
      adminPassword = gets.chomp

      puts "\n\nThat's it! To log in to the bot on IRC, just send the bot the following in a query: LOGIN #{adminUser} #{adminPassword}"
      puts "For more information, please visit the Terminus-Bot web site.\n\n"
      puts "Applying new configuration..."

      # TODO: Needs a little salt.
      adminPassword = Digest::MD5.hexdigest(adminPassword)

      require "includes/classes/adminuser.rb"
      adminUserObj = AdminUser.new(adminUser, adminPassword, 10)

      @config = Hash.new()

      @config["Nick"] = botNick
      @config["Address"] = serverAddress
      @config["Port"] = serverPort.to_i
      @config["Channels"] = channels.split(', ?')
      @config["UserName"] = ident
      @config["RealName"] = realname
      @config["URL"] = "http://github.com/kabaka/Terminus-Bot"
      @config["Version"] = "Terminus-Bot 0.2-alpha"
      @config["QuitMessage"] = "Terminus-Bot: Terminating"
      @config["Prefix"] = ";"
      @config["Throttle"] = 0.1
      @config["Users"] = Hash.new
      @config["Users"][adminUser] = adminUserObj

      puts "Saving configuration to disk..."

      saveConfig

      puts "Done! Continuing with bot start."

    end
  end

  def readConfig()
    FileUtils.copy @configFile, "#{@configFile}.bak"

    $log.debug('config') { "Reading #{@configFile}" }
    @config = YAML::load(File.open(@configFile, 'r'))
    @config = "" unless @config
  end

  def saveConfig()
    FileUtils.touch @configFile unless File.exists? @configFile

    unless File.writable? @configFile
      $log.fatal('config') { "#{@configFile} is not writable!" }
      exit
    end

    $log.debug('config') { "Saving #{@configFile}" }

    YAML::dump(@config, File.open(@configFile, 'w'))
  end

end
