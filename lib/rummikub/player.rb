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

    def refresh(perspective)
      info "new perspective: #{perspective.inspect}"
    end
  end
end
