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

module Bot
  class ClientCapabilities < Array

    require 'base64'

    def initialize(parent)
      @parent = parent

      # SASL
      Events.create(self, :CAP,          :on_cap)
      Events.create(self, :AUTHENTICATE, :on_authenticate)
      Events.create(self, :"904",        :on_sasl_fail)
      Events.create(self, :"905",        :on_sasl_fail)
      Events.create(self, :"900",        :on_sasl_success)
      Events.create(self, :"906",        :on_sasl_abort)
      Events.create(self, :"907",        :on_sasl_abort)

      @sasl_pending = true
    end

    def destroy
      Events.delete_events_for self
    end

    def on_cap(msg)
      return if @parent != msg.connection

      $log.debug("ClientCapabilities.on_cap #{@parent.name}") { msg.raw_str }

      case msg.raw_arr[3]

      when "LS"
        on_cap_ls(msg)

      when "ACK"
        on_cap_ack(msg)

      end
    end

    def on_cap_ls(msg)
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
        msg.raw "CAP END"
        return
      end

      msg.raw "CAP REQ :#{req.join(" ")}"
    end

    def on_cap_ack(msg)
      return if @parent != msg.connection

      @sasl_pending = false

      msg.raw_arr[4..-1].join(" ")[1..-1].downcase.split.each do |cap|
        @sasl_pending = begin_sasl(msg) if cap == "sasl"

        $log.info("ClientCapabilities.on_cap_ack #{@parent.name}") { "Enabled CAP #{cap}" }

        self << cap.gsub(/[^a-z]/, '_').to_sym
      end

      unless @sasl_pending
        msg.raw "CAP END"
      else
        timeout = @parent.config.has_key?(:sasl_timeout) ? @parent.config[:sasl_timeout] : 15
        EM.add_timer(timeout) { sasl_timeout if @sasl_pending }
      end
    end


    def on_authenticate(msg)
      return if @parent != msg.connection

      return unless @sasl_pending

      if msg.raw_arr[1] == "+"
        username = msg.connection.config[:sasl_username]
        password = msg.connection.config[:sasl_password]

        encoded = Base64.encode64("#{username}\0#{username}\0#{password}")

        msg.raw "AUTHENTICATE #{encoded}"

      else

        # TODO: DH-BLOWFISH?

      end
    end

    def begin_sasl(msg)
      if not @parent.config.has_key? :sasl_username or not @parent.config.has_key? :sasl_password
        $log.debug("ClientCapabilities.begin_sasl #{@parent.name}") { "Server supports SASL but we aren't configured to use it." }
        return false
      end

      @sasl_pending = true
      msg.raw "AUTHENTICATE PLAIN"
    end


    def on_sasl_success(msg)
      return if @parent != msg.connection

      @sasl_pending = false

      msg.raw "CAP END"
    end

    def on_sasl_fail(msg)
      return if @parent != msg.connection

      @sasl_pending = false

      msg.raw "CAP END"
    end

    def on_sasl_abort(msg)
      return if @parent != msg.connection

      @sasl_pending = false

      msg.raw "CAP END"
    end

  end
end
