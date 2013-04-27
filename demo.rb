require 'rummikub'

include Rummikub

p1 = Player.new("tim")
p2 = Player.new("anna")
game = Game.new([p1, p2])

sleep
