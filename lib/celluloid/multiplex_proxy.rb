module Celluloid
  class MultiplexProxy < Celluloid::AbstractProxy
    def initialize(parent, uuid, handler_method)
      @parent = parent
      @uuid = uuid
      @handler_method = handler_method
    end

    def method_missing(meth, *args, &block)
      @parent.async(@handler_method, @uuid, meth, *args, &block)
    end
  end
end
