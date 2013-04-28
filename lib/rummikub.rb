require 'rubygems'
require 'bundler/setup'
require 'reel'
require 'pry'

require 'rummikub/version'
require 'rummikub/client'
require 'rummikub/server'

require 'rummikub/game'
require 'rummikub/bag'
require 'rummikub/tile'
require 'rummikub/player'
require 'rummikub/turn'
require 'rummikub/set'

module Rummikub
  GamePerspective = Struct.new(:rack, :opponents)
  TilePerspective = Struct.new(:number, :color)
  OpponentPerspective = Struct.new(:name, :tile_count)
end
