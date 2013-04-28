require 'json'

module Rummikub
  class Client
    class TurnDecoder
      def initialize(message)
        @message = message
      end

      def turn
        case @message['type']
        when 'Pickup'
          Pickup.new
        else
          raise "unknown turn type: #{@message.inspect}"
        end
      end
    end

    include Celluloid::IO
    include Celluloid::Logger

    attr_reader :socket

    def initialize(server, socket)
      @server = server
      @socket = socket
      @name = nil

      async.run
    end

    def run
      info "now running #{inspect}"
      while message = JSON.parse(@socket.read)
        dispatch message
      end
    rescue EOFError
      @server.async.leave(current_actor)
      terminate
    end

    def dispatch(message)
      debug "Dispatching #{message.inspect}"

      case message['action']
      when 'join'
        @name = message['user']
        @server.async.joined(current_actor)
      when 'pickup'
        signal :turn, Pickup.new
      else
        warn "unable to dispatch: #{message.inspect}"
      end
    end

    def take_turn
      deliver action: "take_turn"
      wait :turn
    end

    def refresh(perspective)
      info "new perspective: #{perspective.inspect}"
      rack = perspective.rack.map do |t|
        {number: t.number, color: t.color}
      end
      opponents = perspective.opponents.map do |o|
        {name: o.name, tile_count: o.tile_count}
      end
      deliver action: 'refresh', rack: rack, opponents: opponents
    end

    def deliver(message)
      @socket << JSON.generate(message)
    end

    def name
      @name || "unregistered user"
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)} @name=#{@name.inspect}>"
    end
  end
end
