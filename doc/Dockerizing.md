# Dockerizing your Terminus-Bot instance

I find running Terminus-Bot in a Docker instance to be very convenient for a
number of reasons, because of the ability to isolate its requirements to the
Docker container instead of polluting my system with its dependencies, and
strongly reproducible builds. Because of these advantages, I have come up with
a recommended way to run Terminus-Bot within Docker.

## Setup

### Migrating an existing Terminus-Bot instance

 - Create a directory to house all of your persistent data (I recommend
   `/var/lib/terminus-bot`, as that is where we will be mounting our persistent
   folder within the container)
   - `# mkdir /var/lib/terminus-bot`
 - Copy your existing configuration and your database, and any SSL keys if you
   have them, to this folder.
   - `# cp ~/terminus-bot/terminus-bot.conf /var/lib/terminus-bot/`
   - `# cp ~/terminus-bot/var/terminus-bot/data.db /var/lib/terminus-bot/`
 - If you do use SSL keys, be sure to rewrite the path for them to point to
   their path relative to `/var/lib/terminus-bot`
 - If you didn't choose to use `/var/lib/terminus-bot` as your persistence
   location, modify the `runit` script in `doc/runit/` to point to the correct
   locations.
 - ```
 docker build -t terminus-bot .
 docker run -v /var/lib/terminus-bot:/var/lib/terminus-bot -d terminus-bot
 ```

 - Your Terminus-Bot instance should be up and running now!

### Creating a new Terminus-Bot instance

 - Create a directory to house all of your persistent data (I recommend
   `/var/lib/terminus-bot`, as that is where we will be mounting our persistent
   folder within the container)
   - `# mkdir /var/lib/terminus-bot`
 - Copy the example configuration to the persistence directory and edit it as
   appropriate.
   - `# cp ~/terminus-bot/terminus-bot.conf.dist
     /var/lib/terminus-bot/terminus-bot.conf`

 - If you do use SSL keys, be sure to rewrite the path for them to point to
   their path relative to `/var/lib/terminus-bot`
 - If you didn't choose to use `/var/lib/terminus-bot` as your persistence
   location, modify the `runit` script in `doc/runit/` to point to the correct
   locations.
 - ```
 docker build -t terminus-bot .
 docker run -v /var/lib/terminus-bot:/var/lib/terminus-bot -d terminus-bot
 ```

 - Your Terminus-Bot instance should be up and running now!


## Tips and Tricks

If you use Dokku (I do!), you can create the persistence volume on the host (`#
mkdir /var/lib/terminus-bot-your-tag`) and mount it on the container
automatically by adding `-v
/var/lib/terminus-bot-your-tag:/var/lib/terminus-bot` to
`~dokku/APPNAME/DOCKER_ARGS`, and then proceed as normal. This allows you to
keep your Terminus-Bot configuration confidential as it does contain sensitive
data such as network passwords.
