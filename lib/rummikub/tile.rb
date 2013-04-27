module Rummikub
  class Tile
    include Celluloid
    include Celluloid::Logger

    def initialize(number, color, edition)
      @number = number
      @color = color
      @edition = edition
      @location = nil

      info "created #{name.inspect}"
    end

    def move_to(location)
      info "moving #{name} to #{location.inspect}"
      @location = location
    end

    def located?(location)
      @location == location
    end

    def name
      "%s %s %s" % [@number, @color, @edition]
    end
  end
end
