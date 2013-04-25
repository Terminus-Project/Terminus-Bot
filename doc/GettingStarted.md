# Getting Started with Terminus-Bot

Terminus-Bot is designed to be simple to use, but there are some important
things to keep in mind when configuring it for the first time. This guide
covers many of these concerns.

## Installation

Currently, it is not possible to install Terminus-Bot system-wide. (This is a
[planned feature](https:/github.com/kabaka/Terminus-Bot/issues/26), but will
not be ready until 2.0.). For now, the recommended install method is to simply
clone the git repository to a directory under your home directory.

    git clone git://github.com/kabaka/Terminus-Bot.git

### Dependencies

Terminus-Bot has a very large, growing number of scripts with many diverse
functions. Terminus-Bot itself, as well as some of these scripts, require gems
to function. Presently, there is no automated gem installer included with
Terminus-Bot, as choosing which gems to install can be a complex process.

Only certain scripts require certain gems, so installing all of them is not
ideal for some situations. When preparing to set up your installation of
Terminus-Bot, you can review the list of scripts and add those you don't plan
on using to noload in the configuration, and save yourself some disk space by
not installing their requirements.

#### Core Gem Requirements

* eventmachine - Necessary for the bot to start and connect to IRC.

#### Script Gem Requirements

You only need to install gems for scripts you will be loading.

* dnsruby - dns
* htmlentities - fimfiction, gizoogle, google, rss, title, weather
* multi_json - derpibooru, deviantart, dictionary, fimfiction, github, google,
  imgur, lastfm, mtgox, reddit, twitter, urbandict, wikipedia, xbox, youtube

#### Script System Utility Requirements

Some scripts provide features by running commands installed on the system. In
order to use these scripts, the commands must be available, and Terminus-Bot
must be able to execute them.

* mtr - netutils
* ping - netutils
* ping6 - netutils (for IPv6 support)

*Note that we aggressively sanitize any input passed to commands, though we
cannot guarantee that third-party scripts are secure.*

#### Module Gem Requirements

Modules augment Terminus-Bot's core functionality by making new classes,
modules, or functions available to scripts, or by enabling new non-interactive
features such as new IRC authentication methods.

* em-http-request - http_client

## Configuration

In Terminus-Bot's root directory, you will find a file named
`terminus-bot.conf.dist`. You may either create a copy of this file called
`terminus-bot.conf` or create a new `terminus-bot.conf` by hand. Either way,
use the `terminus-bot.conf.dist` file as a reference for creating your bot's
configuration file.

The reference configuration file is thoroughly documented and should contain
all you need to know. Please **read the entire file** before starting your bot
or you *will* have unexpected things happen.

### noload Section

If you are in a low-memory environment, such as a small VPS, you can reduce
Terminus-Bot's footprint by loading fewer scripts. Review the list of available
scripts and add those you don't want to the `core/noload` section of the
configuration. This will prevent those scripts from loading during start-up.

You may also want to add scripts to this list simply to avoid unwanted
features.

Note: Adding scripts to this list and then rehashing will *not* cause
Terminus-Bot to unload them. Similarly, including a script in this list will
*not* prevent bot administrators from using the `LOAD` command to load the
scripts. `noload` *only* affects what scripts are loaded during start-up.

### admins Section

Make sure your configuration includes an `admin` block with at least one user,
using the syntax explained in the reference configuration file. Without this,
it is impossible to create an administrative account on Terminus-Bot. Making
this account level 10 is highly recommended.

## Running Terminus-Bot

To start Terminus-Bot, simply type `./terminus-bot` in the bot's root
directory. There are optional command-line arguments you may also pass, such
as `-f` to keep the bot in the foreground. Include `-h` or `--help` to see a
complete list of those arguments and their usage.

### On-IRC Configuration

Once Terminus-Bot has started, it will attempt to connect to all of the
networks listed in the configuration. Once connected, it will not join any
channels until you tell it to do so (usually with the `channels` script's
`JOIN` command).

Before you can tell the bot to join any channels, you must register an account
with the name specified in your `admin` block in the configuration. For
example, if you chose the name "admin" in your configuration block, and you
want to use the password "Terminus-Bot rocks!!!" as your password, and your
bot's nick is "Terminus-Bot":

    /msg Terminus-Bot register admin Terminus-Bot rocks!!!

You may subsequently log in with:

    /msg Terminus-Bot identify admin Terminus-Bot rocks!!!

From here, you should now have Terminus-Bot join your channels:

    /msg Terminus-Bot join #example-channel

Once this is complete, you will also be able to use most commands in channels
by prefixing them either with the bot's configured command prefix, or with the
bot's nick, followed by some punctuation:

    <Kabaka> !say hi
    <Terminus-Bot> hi
    <Kabaka> Terminus-Bot: say hi
    <Terminus-Bot> hi

For additional info, see other documentation, the `HELP` command, and the
README.md file.

