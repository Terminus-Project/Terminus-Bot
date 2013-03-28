# Terminus-Bot

chat.freenode.net #Terminus-Bot         http://terminus-bot.net/

# About the Bot

Terminus-Bot is an IRC bot written in Ruby under the MIT license. Its purpose
is to completely avoid the problems of other bots.

The authors of the project are long-time IRC bot users and know how things can
go badly or be confusing. Hopefully, we can address all of the problems we
have encountered, as well as all of those everyone else tells us about.

# Requirements

* Linux
* Ruby 1.9.3
* gems (mandatory)
    * eventmachine
    * psych (included psych has UTF-8 bugs)
* gems (for some scripts)
    * htmlentities
    * json
    * psych 1.2.2
    * dnsruby (dns script)
    * em-http-request (http_client module and all scripts that use it)
    * em-whois (whois script)
    * ruby-mpd (mpd script)
* Script Dependencies
    * netutils: ping, ping6, mtr

# How to use Terminus-Bot

## Installation

Terminus-Bot does not currently support system-wide installation. It may
eventually be made into a gem, but for now you simply download the code and
run it from somewhere in your home directory.

To get the latest Terminus-Bot code, type

    git clone git://github.com/kabaka/Terminus-Bot.git

_Once the bot has reached beta version, there will be separate downloads for
releases of the bot._

## Configuration

Included with the bot is a file called `terminus-bot.conf.dist`. This file
contains the documentation for and examples of the bot's configuration. Using
this file as an example, create `terminus-bot.conf` in the same directory.

*Pay close attention to the documentation in the example configuration file!*
Some configuration values are _required_ for the bot to operate, and many of
them _must_ be in a specific format. Until configuration validation is added
(it will be before the first beta), using invalid configuration values or
leaving out required settings may result in unpredictable behavior or crashes.

By default, the bot will load almost all scripts. The only scripts left out
are those used by developers for debugging, such as the lograw script which
logs every message the bot sees. Refer to the [Scripts](#scripts) section of
this document for a list of scripts and what they do.

Also worth noting are the modules. For a list of modules, refer to the
[Modules](#modules) section of this document.

## Scripts

This is a complete list of all official scripts that are distributed with the
bot. Commands provided by each script are listed here. For more complete
information on what a command does and how to use it, you should view the
on-IRC help for the command by using the [help script's](#help) HELP command.

In these examples, the command prefix used is @. When using the bot, be sure to
use whichever command prefix you set in the core configuration block.

### Account

Create and log in to bot accounts. This script is required if you want access to
administrative functions.

Commands:

* IDENTIFY - Log in to the bot.
* REGISTER - Register a new account on the bot.
* PASSWORD - Change your bot account password.
* FPASSWORD - Change another user's bot account password.
* LEVEL - Change a user's account level.
* ACCOUNT - Display information about a user.
* WHOAMI - Display your current user information if you are logged in.

### Admin

Manage the bot's core functionality.

Commands:

* RELOAD - Reload one or more scripts.
* UNLOAD - Unload one or more scripts.
* LOAD - Load the specified script.
* REHASH - Reload the configuration file.
* NICK - Change the bot's nick for the current connection.
* QUIT - Kill the bot.
* RECONNECT - Reconnect the specified connection.

### Away

Announce away status in channel when users are highlighted. This is pretty
annoying, but some archaic IRC clients don't know how to mark away users in the
nick list, so this _can_ be useful.

Commands:

* AWAY - Enable or disable away status announcements for the current channel.

### Battle

Facilitate PRNG-based role-play battle games. No turn-based enforcement is done,
so it is up to the users how to use this. Once a battle is started, interaction
is done with IRC actions (/me). For example:

    <@Kabaka> @battle start
    <Terminus-Bot> Kabaka has started a battle!
    <Terminus-Bot> To attack other players, use /me attacks TARGET with ITEM
    <Terminus-Bot> You may check the health of active players by using the HEALTH command.
    * Kabaka attacks aji with Hammer of Thor
    <Terminus-Bot> Kabaka's Hammer of Thor hits aji for 12 damage.
    <Terminus-Bot> aji has 88 health remaining.
    * aji attacks Kabaka with pointy sticks
    <Terminus-Bot> Kabaka absorbs the hit and gains 20 health!
    <Terminus-Bot> Kabaka has 120 health remaining.

Starting health, the amount of damage that is possible, and the chance of hits
being ineffective is all configurable in terminus-bot.conf. Any players in the
channel may join in at any time. In large channels, this can get incredibly
hectic, so it is strongly recommended that this script only be used in smaller
channels.

Commands:

* BATTLE - Start, stop, or reset the battle in the current channel.
* HEALTH - View the health of all active players in this channel.
* HEAL - Heal players to maximum health.

### Chanlog

Log channel activity to disk. To disable logging for a specific channel, use the
bot's script flags to disable the script in those channels. Logs are written to
`var/terminus-bot/chanlog/` with the file name format `server.channel.log`.

This script is still experimental and will be subject to extensive changes before beta.

### Channels

Join and part channels, and maintain the list of channels the bot tries to
occupy. Without this script loaded, the bot will not attempt to join any 
channels and will not rejoin channels the next time it starts.

Commands:

* JOIN - Join a channel with optional key.
* PART - Part a channel
* CYCLE - Part and then join a channel.
* JOINCHANS - Force the join channels event.

### Choose

Lets the bot make decisions for you. There are two types of questions you may
ask the bot: Yes/no questions and questions with multiple answers.

To ask a question, begin your message with the bot's commmand prefix followed
by a space. For example:

    <Kabaka> @ Should I go to bed?
    <Terminus-Bot> Kabaka: No

    <Kabaka> @ Ruby, Python, or C?
    <Terminus-Bot> Kabaka: Ruby

### Cipher

Encode and decode text using basic ciphers.

Commands:

* ENCODE - Encode some text using a particular cipher and key.
* DECODE - Decode some text using a particular cipher and key.
* CIPHERS - List the available ciphers.
* ROT13 - Alias for encode/decode rot 13.

### CTCP

Give the bot the ability to respond to some CTCP requests. Without this, the bot
will not be able to respond to things like CTCP PING and CTCP VERSION.

Available CTCPs:

* VERSION - Reply with the bot's version.
* URL - Reply with the bot's home page address.
* TIME - Reply with the current time, formatted according to RFC 822.
* PING - Reply with the text we were sent.
* CLIENTINFO - Reply with a list of supported CTCP commands.

### Dictionary

Provides an interface to dictionary.com. You must have a valid dictionary.com
API key to use this script.

Commands:

* DEFINE - Look up some possibile definitions of a word.
* RANDWORD - Look up the definition of a random word.
* WOTD - Look up the Word of the Day on dictionary.com.
* SPELL - Suggest correct or alternate spellings of a word.
* SLANG - Look up possibly meanings of a slang word.
* ETYMOLOGY - Look up the etymology of a word.

### DNS

Perform DNS look-ups.

Commands:

* DNS - Perform a DNS look-up.
* RDNS - Perform a reverse DNS look-up.

### Eval

Commands:

* EVAL - Run raw Ruby code.

### Factoids

Remember and recall short "factoids." Factoids are short blocks of text. For example:

    <Kabaka> @remember Ruby is the best programming language
    <Terminus-Bot> I will remember that factoid. To recall it, use FACTOID. To delete, use FORGET.
    <Kabaka> @factoid Ruby
    <Terminus-Bot> ruby is the best programming language
    <Kabaka> @forget ruby
    <Terminus-Bot> Factoid forgotten.

Commands:

* REMEMBER - Remember the given factoid.
* FORGET - Forget this factoid.
* FACTOID - Retrieve a factoid.

### Flags

Manage the bot's script flags table.

This script is experimental and will be subject to change before beta.

Terminus-Bot allows you to enable or disable scripts per-channel. This is done
using script "flags." Flags can be on or off for any script in any channel on
any server.

When accessing or modifying the flags table, wildcards are supported.

For example, if we want to disable all scripts on the Freenode network:

    <Kabaka> @disable freenode * *

If we want to see what scripts are enabled in the #Terminus-Bot channel on 
StaticBox:

    <Kabaka> @flags freenode #Terminus-Bot *

Commands:

* ENABLE - Enable scripts in the given server and channel.
* DISABLE - Disable scripts in the given server and channel.
* FLAGS - View flags for given servers, channels, and scripts.

### Games

Provides a few basic gaming commands.

Commands:

* DICE - Roll dice.
* EIGHTBALL - Shake the 8-ball.
* COIN - Flip a coin.

### Google

Search the Internet with Google.

Commands:

* G - Search for web pages using Google.
* GIMAGE - Search for images using Google.
* GVIDEO - Search for videos using Google.
* GBOOK - Search books using Google.
* GPATENT - Search patents using Google.
* GBLOG - Search blogs using Google.
* GNEWS - Search news using Google.


### Help

Provide on-IRC help for bot commands and scripts.

Commands:

* HELP - Show help for the given command or a list of all commands.
* SCRIPT - Show a description of the given script or a list of all scripts.

### IdleRPG

Allows the bot to play Idle RPG and/or interface with an XML API to look-up
information about other players.

Commands:

* IDLERPG - Get information about players on this network's IdleRPG game.

### Ignore

Manage the bot's ignore list. Ignores are wildcard-matched strings in the format
`nick!user@host`.

Commands:

* IGNORE - Ignore the given hostmask.
* UNIGNORE - Remove the given ignore.
* IGNORES - List all active ignores.

### LastFM

Access information on last.fm.

Script script is experimental and will be subject to change before beta.

Commands:

* NP - Show the currently playing track for the given last.fm user.

### Lograw

Log all messages the bot sees. Messages are logged to the core logger, so
information is in `var/terminus-bot.log`. This script is primarily intended
for developer use and will not be helpful to most users.

### Markov

Create Markov chains based on word statistics collected by the bot.

This script is experimental and will be subject to change before beta.

*If you are in a low-memory environment, _do not_ use this script!*
Commands:

* MARKOV - Manage the Markov script.
* CHAIN - Generate a random Markov chain.

### MPD

Interface with a Music Player Daemon script and optionally announce status
changes to an IRC channel (useful for Internet radio stations).

Commands:

* MPD - Interact with MPD. Parameters:
  * NEXT - Play the next track in the queue.
  * PREVIOUS - Play the previous track in the queue.
  * STOP - Stop playback.
  * PLAY - Start or resume playback.
  * PAUSE - Pause playback.
  * SHUFFLE - Shuffle the queue.
  * UPDATE - Begin MPD database update.
  * RESCAN - Begin MPD database update, also rescanning unchanged files.
  * SEARCH? - Search the database for matching tracks, any tag.
  * COUNT? - Search the database, exact matches only. Parameters: tag values
  * NEXT? - Show the name of the next track that will be played.
  * PLAYLIST? - Show information about the current queue.
  * NP? - Show the currently playing track.
  * AUDIO? - Show technical information about the currently playing track.
  * DATABASE? - Show information about the MPD database.

### Nato

Convert text to the NATO phonetic alphabet.

Commands:

* NATO - Convert text to the NATO phonetic alphabet.

### Netutils

Provides access to network tools such as ping and mtr.

The ping and mtr utilities must be installed on the host system and accessible
to whatever user started the bot. For IPv6 commands to work, the host system
must have IPv6 connectivity.

Commands:

* ICMP - Check if the given host is up and answering pings.
* ICMP6 - Check if the given IPv6 host is up and answering pings.
* MTR - Show data about the route to the given host.
* MTR6 - Show data about the route to the given IPv6 host.

### Networks

Show information about the networks to which the bot is connected.

Commands:

* NETWORKS - Show a list of networks to which the bot is connected.

### Pandora

Provides an interface to pandorabots.com, a hosted ALICE chat bot provider. A
valid bot ID (like an API key) is required to use this script.

To talk to the bot once interactivity is enabled, simple begin your messages
with the bot's nick like you might do when speaking to another user in the
channel.

Conversations are tracked per-channel, not per-user. So when multiple users
in one channel are talking to the bot, it will consider them all to be the
same person.

    <Kabaka> @pandora on
    <Terminus-Bot> Pandorabot interaction enabled.
    <Kabaka> Terminus-Bot: Hi
    <Terminus-Bot> Kabaka: Hello there!

Commands:

* PANDORA - Enable or disable Pandorabot interaction.

### Ping

Allows users to check the round-trip time for a CTCP PING with the bot.

Commands:

* PING - Measure the time it takes for the bot to receive a reply to a CTCP
PING from your client.

### Pong

Reply to server PINGs. Without this script loaded, the bot will frequently
disconnect due to ping timeouts.

### Raw

Commands:

* RAW - Send raw text over the IRC connection.

### Regex

Perform regular expression substitutions and searches on recent messages.

Substitutions are done with sed-like message syntax: s/regex/replacement/flags

Searches are done with: g/regex/flags

For example:

    <Kabaka> I'm writting documentation for Terminus-Bot!
    <Kabaka> s/writting/writing/
    <Terminus-Bot> <Kabaka> I'm writing documentation for Terminus-Bot!

    <Kabaka> This is a test.
    <Kabaka> s/[aeiou]//g
    <Terminus-Bot> <Kabaka> Ths s  tst.

### Relay

Relay chat between two or more channels on one or more networks.

This script is _highly_ experimental is will be subject to change before beta.
There are multiple known problems with this script, so production use is not
recommended.

Commands:

* RELAY - Manage channel relays.
* RELAYS - List active channel relays.

### Roulette

Russian Roulette for IRC.

If the bot is a channel operator when a user loses, the bot will kick the user.
If not, it will just announce it as a channel message.

Commands:

* ROULETTE - Pull the trigger. You have a 5/6 chance of surviving.

### RPN

Reverse Polish notation (postfix) calculator.

Commands:

* RPN - Perform calculations in Reverse Polish notation.

Operators for RPN command:

* +, add - Add the two top stack values.
* -, sub - Subtract the two top stack values.
* \*, mul - Multiply the two top stack values.
* \**, exp - Raise one top stack value to the power of the one below it.
* %, mod - Perform modulus divsion on the two top stack values.
* p - Print the top stack value.
* f - Print the full stack.

### RSS

Automatically check RSS and ATOM feeds and post updates to channels.

Commands:

* RSS - Manage the RSS/ATOM feeds for the current channel.

### Seen

Tracks when the bot has last seen a nick speaking.

Commands:

* SEEN - Check when the given user was last seen speaking on IRC.

### Source

Provides a link to the bot's home page.

Commands:

* SOURCE - Share info about the bot and its source code.

### Speak

Allows bot admins to use the bot to speak and perform actions.

Commands:

* SAY - Speak the given text.
* ACT - Act the given text (CTCP ACTION).

### Tell

Leave messages for inactive users. This is basically an in-channel MemoServ.
If MemoServ is available, it is almost definitely a better solution, as this
script has some privacy and abuse concerns.

Commands:

* TELL - Have the bot tell the given user something the next time they speak.

### Time

Commands:

* TIME - Get the current time with optional time format.

### Title

Display the titles of web pages when the bot sees links in channels.

In addition to basic title retrieval, the bot handles several special cases:

* YouTube videos
* Twitter posts
* GitHub repositories
* GitHub commits
* deviantART posts
* FIMFiction.net stories
* Derpibooru posts

More sites may be added later.

### Uptime

Commands:

* UPTIME - Show how long the bot has been active.

### Urbandict

Look up words on urbandictionary.com.

Because Urban Dictionary doesn't offer an API anymore, we have to scrape the
web pages for information. Hopefully they'll have an API again at some point.

Commands:

* UD - Fetch the definition of a word from UrbanDictionary.com. If no word is
  given, fetch a random definition.

### Weather

Look up weather on wunderground.com.

Locations can be specified in many ways for this script. For instance, you can
give a zip code, city/state, or a weather station identifier.

Commands:

* WEATHER - View current conditions for the specified location.
* TEMP - View the current temperature for the specified location.
* FORECAST - View a short-term forecast for the specified location.

### WHOIS

Look up domain registration information.

Commands:

* WHOIS - View domain registration informatiaon for the specified domain name.

### Wikipedia

Look up information and pages on Wikipedia. Queries are searches, so it isn't
important that you provide an exact page title.

Commands:

* WIKI - Search Wikipedia for the given text.

### Xbox

Look up information on Xbox Live players and games.

Commands:

* XBOX - Display inforation about Xbox Live players.
  * PROFILE - Show the current status and information about the given gamer tag.
  * ACHIEVEMENTS - Show achievements for the given gamer tag with optional game.
  * FRIENDS - Show a list of friends for the given gamer tag, if available.

## Modules

Modules are files that augment the bot's core code. They cannot be unloaded or
reloaded. Some are required by some scripts.

### buffer

A short-term, in-memory message history. It is currently not required by any
scripts, but will be eventually used by the regex script.

### caps

Client capability negotiation. With this module loaded, the bot can use modern
IRC features such as multi-prefix and SASL to help improve security and reduce
bandwidth usage. Loading this module is strongly recommended.

### http-client

Simplifies HTTP access for scripts. This module handles redirects, timeouts, and
headers.

### ignores

Allows the bot to ignore other users. This is managed by the
[ignore script](#ignore).

## First Run

After you've completed configuration of the bot, type `./terminus-bot` in the
bot's directory. The bot will load all files and then disappear into the
background. It should then connect to IRC.

Since it won't join any channels until you tell it to, you'll have to manually
open a query with it by typing `/query Terminus-Bot` (replacing "Terminus-Bot"
with whatever nick you gave the bot).

From here, you'll need to register an account with the bot. When writing the
configuration file, you should have specified at least one level 10 account in
the admins block. Use that account name to register your new account using the
`register` command in the account script.

The bot should inform you that you've been logged in. Go ahead and have it join
a channel using the channel script's `join` command.

Remember, you can use the help script's `help` command to get a list of commands
and help with specific commands. The command list will only show you commands
you are authorized to use.

## Reporting Problems

Remember, Terminus-Bot is not yet done, so some things may not work correctly.
If you get stuck, or if something just isn't working, make sure you read the
relevant help and make sure you are not making a mistake. Once you're sure
there is a problem with your Terminus-Bot, head to the IRC channel at the top
of this document and ask one of the channel operators what to do. If there is
a bug, we'll probably need you to reproduce it with debug logging enabled so
that we can get a backtrace.

