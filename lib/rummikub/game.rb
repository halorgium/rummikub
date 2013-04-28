module Rummikub
  class Game
    class Reiterator
      def initialize(ary)
        @iterator = ary.each
      end

      def next
        @iterator.next
      rescue StopIteration
        @iterator.rewind
        retry
      end
    end

    include Celluloid
    include Celluloid::Logger

    def initialize(players)
      info "creating with players: #{players.map(&:name)}"
      @players = players
      @bag = Bag.new
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
      @players.each do |player|
        14.times do
          tile = with_bag_tile
          tile.move_to(player)
        end
      end

      iterator = Reiterator.new(@players.sort_by { rand })
      while player = iterator.next
        broadcast

        info "asking #{player.inspect} to take their turn"
        turn = player.take_turn
        case turn
        when Pickup
          tile = with_bag_tile
          tile.move_to player
        else
          raise "do not know how to complete turn: #{turn.inspect}"
        end
      end
    end

    def broadcast
      @players.each do |player|
        opponents = []
        @players.each do |opponent|
          next if opponent == player
          opponents << OpponentPerspective.new(opponent.name, tiles_in(opponent).size)
        end
        tiles = []
        tiles_in(player).each do |tile|
          tiles << TilePerspective.new(tile.number, tile.color)
        end
        perspective = GamePerspective.new(tiles, opponents)
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
