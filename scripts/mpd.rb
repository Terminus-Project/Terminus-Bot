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

require 'ruby-mpd'

register 'Interact with a Music Player Daemon instance.'

command 'mpd', 'Interact with MPD. Syntax: mpd next|previous|stop|play|pause|shuffle|update|rescan|search?|count?|next?|queue?|np?|audio?|database?' do
  argc! 1

  args = @params.first.split

  case args.shift.downcase.to_sym
  when :next
    level! 4

    connect
    @@mpd.next

    reply 'Playing next track.'
    check_status

  when :previous
    level! 4

    connect
    @@mpd.previous

    reply 'Playing previous track.'
    check_status

  when :stop
    level! 4

    connect
    @@mpd.stop

    reply 'Playback stopped.'
    check_status
  
  when :play
    level! 4

    connect
    @@mpd.play
    
    reply 'Playback started/resumed.'
    check_status

  when :pause
    level! 4

    connect
    @@mpd.pause
    
    reply 'Playback paused.'
    check_status
    
  when :shuffle
    level! 4

    connect
     @@mpd.shuffle

    reply 'Queue shuffled.'

  when :update
    level! 4

    connect
    @@mpd.update

    reply 'Database update started.'

  when :rescan
    level! 4

    connect
    @@mpd.rescan

    reply 'Database update with full rescan started.'

  when :add
    level! 4

    connect

    @@mpd.search :any, args.join(' '), :add => true
    
    reply 'Added matching tracks to queue.'

  when :addplay
    level! 4

    connect
    
    add_pos = queue.length

     @@mpd.search :any, args.join(' '), :add => true
     @@mpd.play add_pos

     reply 'Added matching tracks to queue and started playback.'

  when :search?
    connect
    results = @@mpd.search :any, args.join(' ')
    
    duration = results.inject(0) {|sum, s| sum + s.time}
    duration = Time.at(Time.now.to_i + duration).to_duration_s

    data = {
      'Tracks'    => results.length,
      'Duration'  => duration
    }

    reply data, false


  when :count?
    connect
    results = @@mpd.count args.shift.downcase.to_sym, args.join(' ')
 
    duration = Time.at(Time.now.to_i + results[:playtime]).to_duration_s

    data = {
      'Tracks'    => results[:songs],
      'Duration'  => duration
    }

    reply data

  when :next?
    connect
    song = @@mpd.song_with_id status[:nextsongid]

    data = {
      'Next Track' => song_to_s(song)
    }

    reply data, false

  when :queue?
    my_queue  = queue

    length    = queue.length
    duration  = queue.inject(0) {|sum, s| sum + s.time}

    duration = Time.at(Time.now.to_i + duration).to_duration_s

    data = {
      'Queue' => {
        'Tracks'    => length,
        'Duration'  => duration
      }
    }

    reply data, false

  when :np?
    say_now_playing

  when :audio?
    audio = status[:audio]

    data = {
      'Audio' => {
        'Rate'      => audio.shift,
        'Bits'      => audio.shift,
        'Channels'  => audio.shift
      } 
    }

    reply data, false

  when :database?
    my_stats = stats

    playtime = Time.at(Time.now.to_i + my_stats[:db_playtime]).to_duration_s

    data = {
      'Artists'   => my_stats[:artists],
      'Tracks'    => my_stats[:songs],
      'Play Time' => playtime
    }

    reply data, false

  else
    raise 'Unknown MPD command.'

  end
end

event :done_loading do
  start if EM.reactor_running?
end

event :em_started do
  start
end


helpers do

  def start
    @@mpd = MPD.new get_config(:address, 'localhost'), get_config(:port, 6600)

    password = get_config :password, nil

    @@mpd.password password if password
    @@mpd.connect

    @@previous_song  = nil
    @@previous_state = :unknown

    server = get_config :announce_server, nil
    chan   = get_config :announce_channel, nil

    return unless server and chan

    @@announce_server  = server.to_sym
    @@announce_channel = chan

    @@timer = EM.add_periodic_timer(get_config(:announce_check_interval, 5).to_i) do
      check_status
    end
  end

  def check_status
    connect

    my_state = state

    if @@previous_state != my_state
      state_changed my_state
    end

    return if my_state == :stop or my_state == :pause

    song = current_song

    if @@previous_song.nil? or not song == @@previous_song
      track_changed song
    end
  end

  def state_changed new_state
    case new_state
    when :stop
      announce "MPD is now: \02STOPPED\02"
    when :play
      announce "MPD is now: \02PLAYING\02"
    when :pause
      announce "MPD is now: \02PAUSED\02"
    end

    @@previous_state = new_state
  end

  def track_changed song
    announce "Current track: \02#{song_to_s song}\02"

    @@previous_song = song
  end

  def announce msg
    return unless @@announce_server and @@announce_channel

    Bot::Connections[@@announce_server].send_privmsg @@announce_channel, msg
  end

  def say_now_playing
    unless state == :play
      reply "MPD is currently not playing."
    else
      reply "Current track: \02#{song_to_s current_song}\02", false
    end
  end

  def connect
    @@mpd.connect unless @@mpd.connected?

    password = get_config :password, nil

    @@mpd.password password if password
  end

  def state
    s = status
    s = status if status === true
    s[:state]
  end

  def status
    connect
    @@mpd.status
  end

  def stats
    connect
    @@mpd.stats
  end

  def queue
    connect
    @@mpd.queue
  end

  def current_song
    connect
    @@mpd.current_song
  end

  # TODO: move to Song class if possible
  def song_to_s song
    s = []

    s << song.artist if song.artist
    s << song.album  if song.album
    s << song.title  if song.title

    s << song.file   if s.empty?

    s.join(' - ')
  end

  def die
    @@mpd.disconnect
    @@timer.cancel
  end
end

