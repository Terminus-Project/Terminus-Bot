#
# Copyright (C) 2010-2015 Kyle Johnson <kyle@vacantminded.com>, Alex Iadicicco
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

  MODULE_LOADED_CLIENT_CAPABILITIES  = true
  MODULE_VERSION_CLIENT_CAPABILITIES = 0.5

  class ClientCapabilities < Array

    require 'base64'

    def initialize parent
      @parent = parent

      # SASL
      Events.create :CAP,          self, :on_cap
      Events.create :AUTHENTICATE, self, :on_authenticate
      Events.create :"904",        self, :on_sasl_fail
      Events.create :"905",        self, :on_sasl_fail
      Events.create :"900",        self, :on_sasl_success
      Events.create :"903",        self, :on_sasl_success
      Events.create :"906",        self, :on_sasl_abort
      Events.create :"907",        self, :on_sasl_abort

      @sasl_pending = true
    end

    def destroy
      Events.delete_events_for self
    end

    def on_cap msg
      return if @parent != msg.connection

      $log.debug("ClientCapabilities.on_cap #{@parent.name}") { msg.raw_str }

      case msg.raw_arr[3]

      when "LS"
        on_cap_ls msg

      when "ACK"
        on_cap_ack msg

      end
    end

    def on_cap_ls msg
      return if @parent != msg.connection

      req = []

      # TODO: This thing (and the one in on_cap_ack) is insane. Fix it in Message.
      msg.raw_arr[4..-1].join(" ")[1..-1].split.each do |cap|
        cap.downcase!

        case cap

          # TODO: Support more?

        when "sasl"
          req << cap

        when "multi-prefix"
          req << cap

        end

      end

      if req.empty?
        msg.connection.raw "CAP END"
        return
      end

      msg.connection.raw "CAP REQ :#{req.join(" ")}"
    end

    def on_cap_ack msg
      return if @parent != msg.connection

      @sasl_pending = false

      msg.raw_arr[4..-1].join(" ")[1..-1].downcase.split.each do |cap|
        @sasl_pending = begin_sasl(msg) if cap == "sasl"

        $log.info("ClientCapabilities.on_cap_ack #{@parent.name}") { "Enabled CAP #{cap}" }

        self << cap.tr('^a-z', '_').to_sym
      end

      unless @sasl_pending
        msg.connection.raw "CAP END"
      else
        timeout = @parent.config.key?(:sasl_timeout) ? @parent.config[:sasl_timeout] : 15
        EM.add_timer(timeout) { sasl_timeout msg if @sasl_pending }
      end
    end


    def on_authenticate msg
      return if @parent != msg.connection

      return unless @sasl_pending

      if msg.raw_arr[1] == "+"
        username = msg.connection.config[:sasl_username]
        password = msg.connection.config[:sasl_password]

        encoded = Base64.encode64 "#{username}\0#{username}\0#{password}"

        msg.connection.raw "AUTHENTICATE #{encoded}"

      else

        # TODO: DH-BLOWFISH?

      end
    end

    def begin_sasl msg
      if not @parent.config.key? :sasl_username or not @parent.config.key? :sasl_password
        $log.debug("ClientCapabilities.begin_sasl #{@parent.name}") { "Server supports SASL but we aren't configured to use it." }
        return false
      end

      @sasl_pending = true
      msg.connection.raw "AUTHENTICATE PLAIN"
    end

    def sasl_timeout msg
      return unless @sasl_pending

      $log.warn("ClientCapabilities.sasl_timeout #{@parent.name}") { "SASL authentication timed out." }

      on_sasl_abort msg
    end


    def on_sasl_success msg
      return if @parent != msg.connection

      @sasl_pending = false

      msg.connection.raw "CAP END"
    end

    def on_sasl_fail msg
      return if @parent != msg.connection

      @sasl_pending = false

      msg.connection.raw "CAP END"
    end

    def on_sasl_abort msg
      return if @parent != msg.connection

      @sasl_pending = false

      msg.connection.raw "CAP END"
    end

  end
end
# vim: set tabstop=2 expandtab:
