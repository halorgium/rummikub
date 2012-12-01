require 'json'

module Reeltalk
  class Client
    include Celluloid::IO
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :socket

    def initialize(socket)
      @socket = socket
      @nickname = nil

      subscribe 'chat', :handle_chat
      async.run
    end

    def run
      while message = JSON.parse(@socket.read)
        dispatch message
      end
    rescue EOFError
      info "#{nickname} disconnected"
      terminate
    end

    def dispatch(message)
      debug "Dispatching #{message.inspect}"

      case message['action']
      when 'join'
        @nickname = message['user']
        info "#{nickname} joined"
        publish 'chat', message
      when 'message'
        publish 'chat', message.merge('user' => @nickname)
      else
        warn "unknown command '#{action}'"
      end
    end

    def handle_chat(_, message)
      @socket << JSON.generate(message)
    end

    def nickname
      @nickname || "unregistered user"
    end
  end
end