![Terminus-Bot: The IRC Bot to End All Others](http://terminus-project.org/static-assets/terminus-bot-logo-for-white-bg.png)

[terminus-bot.net](http://terminus-bot.net/)

[chat.freenode.net #Terminus-Bot](irc://chat.freenode.net/Terminus-Bot)

[![Join the chat at https://gitter.im/Terminus-Project/Terminus-Bot](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Terminus-Project/Terminus-Bot?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# About the Bot

Terminus-Bot is an IRC bot written in Ruby under the MIT license. Its purpose
is to completely avoid the problems of other bots.

The authors of the project are long-time IRC bot users and know how things can
go badly or be confusing. Hopefully, we can address all of the problems we
have encountered, as well as all of those everyone else tells us about.

# Requirements

* Linux
* Ruby 1.9.3 or 2.0
* gems (mandatory)
    * eventmachine (*should be built with SSL support*)
    * psych (included psych has UTF-8 bugs)
* gems (for some scripts)
    * htmlentities
    * multi_json
    * psych 1.2.2
    * dnsruby (dns script)
    * em-http-request (http_client module and all scripts that use it)
    * em-whois (whois script)
    * ruby-mpd (mpd script)
* Script Dependencies
    * netutils: ping, ping6, mtr

# How to use Terminus-Bot

## Installation and Configuration

See `doc/GettingStarted.md`.

After that, if you are interested in running Terminus-Bot in a Docker
container, see `doc/Dockerizing.md`.

## Code Documentation and Guides

Documentation, including most internal and scripting APIs, is hosted at
[http://terminus-project.org/terminus-bot/doc/index.html](http://terminus-project.org/terminus-bot/doc/index.html).
These docs are a work in progress; contributions are welcome!

You may also generate these docs by running `yard` from the project root
(this requires the yard and redcarpet gems).

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

### Backspace

React to `^H`, `^W`, `^U`, and `^Y` by displaying the resulting text.

* `^H` - Backspace
* `^W` - Delete last word
* `^U` - Delete line
* `^Y` - Paste buffer (from `^W` or `^U`)

### Base

Convert a number from one numeric base to another.

Commands:

* BASE - Convert a number from the specified base to another specified base.
* HEX - Convert a number between decimal and hexadecimal.

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

### Derpibooru

Search for and look up images on [Derpibooru](https://derpiboo.ru/). Search
syntax is identical to that on the web site.

Commands:

* DERPI
  * IMAGE - Display information about the given image ID.
  * SEARCH - Look up the most recent image with the given tags.
  * RANDOM - Show a random, somewhat recent image with the given tags.

### DNS

Perform DNS look-ups.

Commands:

* DNS - Perform a DNS look-up.
* RDNS - Perform a reverse DNS look-up.

### DuckDuckGo

Query DuckDuckGo.com.

Commands:

* ASK - Ask DuckDuckGo to complete a complex query. See 
  https://duckduckgo.com/goodies
* DDG - Retrieve the first instant search result from DuckDuckGo.
* DEFINE - Fetch a short definition or other information about a given term.

### e621

Search for and look up iamges on [e621](https://e621.net). Search syntax is
identical to that on the site.

Commands:

* E621
  * IMAGE - Display information about the given image ID.
  * SEARCH - Look up the most recent image with the given tags.
  * RANDOM - Show a random, somewhat recent image with the given tags.

### Eval

Commands:

* EVAL - Run raw Ruby code.

### Exchange

Get up-to-date exchange rates from openexhangerates.org. Requires an API key.
Sign up free: https://openexchangerates.org/signup/free

Commands:

* EXCHANGE - Get the current exchange rate for the given currencies.

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

### Flist

Interact with F-list.net.

**Note: for access to character information, the character owner must have
enabled API access in their account settings.**

Commands:

* F-LIST
  * CHARACTER - Look up general info about the given character.
  * COMPARE - Compare the kinks of two characters.

### FOAAS

Interact with the FOAAS service at
[foaas.herokuapp.com](https://foaas.herokuapp.com/).

Commands:

* FUCK
  * OFF - Tell someone how much you are enjoying talking with them.
  * YOU - Express your feelings for someone.
  * THIS - Declare your dislike of something.
  * THAT - Declare your dislike of something else.
  * EVERYTHING - Declare your hatred for the world.
  * EVERYONE - Announce your displeasure with the people around you.
  * DONUT - Give someone a helpful suggestion.
  * LINUS - Direct a useful quotation from Linus at someone.
  * PINK - The best color.


### Games

Provides a few basic gaming commands.

Commands:

* DICE - Roll dice.
* EIGHTBALL - Shake the 8-ball.
* COIN - Flip a coin.
* RPS - Play Rock-paper-scissors against the bot.

### Gizoogle

"Translate" text using [Gizoogle](http://www.gizoogle.net/).

*Note: Gizoogle has no API as of the time of writing, so this script scrapes
the web page. Because of this, it may be prone to breakage.*

Commands:

* GIZOOGLE - Translate the given text.

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

### ICNDB

Get jokes from the Internet Chuck Norris Database.

Commands:

* NORRIS - Get a joke. Optionally, include a first and last name to use instead
  of "Chuck Norris."

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

### IsUp

Check the availability and responsiveness of web services.

URI syntax is the usual `protocol://hostname:port`. If no port is given and the
protocol has a default port, it is used.

Supported protocols are currently:

* HTTP
* HTTPS

Commands:

* CHECK - Check the service at the given URI for proper response and response
  time.

### Karma

Track user "karma" based on observed `nick++` and `nick--` messages.

Commands:

* KARMA - Show your karma or the karma of another user.

### LastFM

Access information on last.fm.

Script script is experimental and will be subject to change before beta.

Commands:

* NP - Show the currently playing track for the given last.fm user.
* TASTEOMETER - Show the musical compatibility of two users.

### Lorem

Retrieve Lorem Ipsum placeholder text from [loripsum.net](http://loripsum.net).

Commands:

* LOREM - Retrieve and display one paragraph of Lorem Ipsum text.

### LMGTFY

Generate "Let Me Google That For You" links.

Commands:

* LMGTFY - Output a link to the "Let Me Google That For You" site with the
  given query.

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
  * QUEUE? - Show information about the current queue.
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

### Numbers

Retrieve interesting number facts from numbersapi.com.

Commands:

* NUMBERS - Show a fact about the given number. Optionally, include a type,
  such as "date".

### Ping

Allows users to check the round-trip time for a CTCP PING with the bot.

Commands:

* PING - Measure the time it takes for the bot to receive a reply to a CTCP
PING from your client.

### Pong

Reply to server PINGs. Without this script loaded, the bot will frequently
disconnect due to ping timeouts.

### Potassium

Track user K intake.

Comands:

* POTASSIUM - Check your potassium or the potassium of another user.
* HYPERKALAEMIA - Find out who has the most potassium.
* HYPOKALAEMIA - Find out who has the least potassium.

### Rainbows

Make text more colorful.

Recent messages are searched by regular expression with `r//`. Please your
search expression between the slashes. You may include one of the following
flags after the last slash:

* i - Case-insensitive search.
* r - Randomize colors.
* b - Change background color.
* w - Change colors per word rather than per character.
* l - Change colors for the entire line rather than per character.
* s - Remove formatting from matching message.

### Raw

Commands:

* RAW - Send raw text over the IRC connection.

### Reddit

Handle reddit URLs and interact with reddit.

Commands:

* SERENDIPITY - Get a random reddit post.

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

### SoFurry

Retrieve submission information and other data from sofurry.com.

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

### Translate

Provides an interface to glosbe.com.

Commands:

* TRANSLATE - Translate words using glosbe.com.

### UPC

Look up UPC codes on upcdatabase.org.

Commands:

* UPC - Look up a UPC code.

### Uptime

Commands:

* UPTIME - Show how long the bot has been active.

### Urbandict

Look up words on urbandictionary.com.

Uses the new (unannounced?) JSON API.

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

## Modules

Modules are files that augment the bot's core code. They cannot be unloaded or
reloaded. Some are required by some scripts.

### buffer

A short-term, in-memory message history. This is used by the regex script for
quick searching of recent messages for subtitution, and can easily be used by
other scripts.

### caps

Client capability negotiation. With this module loaded, the bot can use modern
IRC features such as multi-prefix and SASL to help improve security and reduce
bandwidth usage. Loading this module is strongly recommended.

### http_client

Simplifies HTTP access for scripts. This module handles redirects, timeouts, and
headers.

### ignores

Allows the bot to ignore other users. This is managed by the
[ignore script](#ignore).

### regex_handler

Provides an easy-to-use way for scripts to act on messages matching regular
expressions.

For usage examples, see the Reddit script and others.

### url_handler

Provides an easy-to-use way for scripts to react to URLs the bot sees in chat.

For usage examples, see the title script, Wikipedia script, and others.

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
and help with specific commands.

## Reporting Problems

Remember, Terminus-Bot is not yet done, so some things may not work correctly.
If you get stuck, or if something just isn't working, make sure you read the
relevant help and make sure you are not making a mistake. Once you're sure
there is a problem with your Terminus-Bot, head to the IRC channel at the top
of this document and ask one of the channel operators what to do. If there is
a bug, we'll probably need you to reproduce it with debug logging enabled so
that we can get a backtrace.

