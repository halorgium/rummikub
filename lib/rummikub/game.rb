module Rummikub
  class Game
    include Celluloid
    include Celluloid::Logger

    def initialize(players)
      info "creating with players: #{players.inspect}"
      @players = players
      @bag = Bag.new
      @sets = []
      @tiles = []
      %w( red yellow green blue ).each do |color|
        (1..13).each do |number|
          2.times do |edition|
            Tile.new(number, color, edition).tap do |tile|
              @tiles << tile
              tile.move_to(@bag)
            end
          end
        end
      end

      async.start
    end

    def start
      info "players: #{@players.inspect}"
      @players.each do |player|
        info "giving tiles to #{player.inspect}"
        14.times do
          tile = with_bag_tile
          tile.move_to(player)
        end
        player.start(current_actor)
      end

      info "starting game"

      @players.sort_by! { rand }
      @players.cycle do |player|
        broadcast

        info "asking #{player.inspect} to take their turn"
        turn = player.take_turn
        case turn
        when Pickup
          info "#{player.inspect} asked to pickup"
          tile = with_bag_tile
          tile.move_to player
        when Finished
          info "#{player.inspect} is finished"
        else
          raise "do not know how to complete turn: #{turn.inspect}"
        end
      end
    end

    def add_set
      Set.new.tap do |set|
        @sets << set
        broadcast
      end
    end

    def find_set(index)
      if @sets.include?(index)
        index
      else
        @sets.fetch(index, nil)
      end
    end

    def move_tile(number, color, source, destination)
      tiles_in(source).each do |tile|
        if tile.number == number && tile.color == color
          tile.move_to(destination)
          break
        end
      end
      broadcast
    end

    def broadcast
      @players.each do |player|
        tiles = tiles_in(player).map do |tile|
          TilePerspective.new(tile.number, tile.color)
        end
        sets = @sets.map.with_index do |set,i|
          [i, tiles_in(set).map do |tile|
            TilePerspective.new(tile.number, tile.color)
          end]
        end
        opponents = []
        @players.each do |opponent|
          next if opponent == player
          opponents << OpponentPerspective.new(opponent.name, tiles_in(opponent).size)
        end
        perspective = GamePerspective.new(tiles, sets, opponents)
        player.refresh(perspective)
      end
    end

    def with_bag_tile
      tiles = tiles_in(@bag).sort_by! { rand }
      tiles.first || raise("no more tiles left in the bag")
    end

    def tiles_in(location)
      @tiles.select do |tile|
        tile.located?(location)
      end
    end
  end
end
