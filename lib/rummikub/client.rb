require 'json'

module Rummikub
  class Client
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
        action = message.fetch('action')
        body = message.fetch('body', nil)
        dispatch action, body
      end
    rescue EOFError
      @server.leave
      terminate
    end

    def dispatch(action, body)
      debug "Dispatching #{action.inspect} with #{body.inspect}"

      case action
      when 'join'
        @name = body['user']
        @server.joined
      when 'pickup'
        signal :turn, Pickup.new
      when 'finished'
        signal :turn, Finished.new
      when 'add-set'
        add_set(body.fetch('source', nil), body.fetch('tile'))
      when 'move-tile'
        move_tile(body.fetch('source', nil), body.fetch('destination', nil), body.fetch('tile'))
      else
        warn "unable to dispatch: #{action.inspect}"
      end
    end

    def start(game)
      @game = game
    end

    def add_set(source, tile)
      destination = @game.add_set
      move_tile(source, destination, tile)
    end

    def move_tile(source, destination, tile)
      source = source ? @game.find_set(source) : current_actor
      destination = destination ? @game.find_set(destination) : current_actor
      @game.move_tile(tile.fetch("number"), tile.fetch("color"), source, destination)
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
      sets = perspective.sets.map do |(index,tiles)|
        tiles = tiles.map do |t|
          {number: t.number, color: t.color}
        end
        {index: index, tiles: tiles}
      end
      opponents = perspective.opponents.map do |o|
        {name: o.name, tile_count: o.tile_count}
      end
      deliver action: 'refresh', rack: rack, sets: sets, opponents: opponents
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
