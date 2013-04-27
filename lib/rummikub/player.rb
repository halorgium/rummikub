module Rummikub
  class Player
    include Celluloid
    include Celluloid::Logger

    def initialize(name)
      info "creating with name: #{name.inspect}"
      @name = name
    end
    attr_reader :name

    def take_turn
      Pickup.new
    end
  end
end
