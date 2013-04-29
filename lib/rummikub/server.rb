module Rummikub
  PUBLIC_ROOT  = Pathname.new File.expand_path("../../../public", __FILE__)
  PUBLIC_FILES = Dir[PUBLIC_ROOT.join("**", "*")].map { |f| f.sub(/^#{PUBLIC_ROOT}\//, '') }
  
  class Server < Reel::Server
    include Celluloid::Logger

    class ClientFacet
      def initialize(server, client)
        @server = server
        @client = client
      end

      def joined
        @server.find_game(@client)
      end
    end

    def initialize(host = "127.0.0.1", port = 1234)
      info "Rummikub starting on http://#{host}:#{port}"
      @clients = {}
      @waiting = []
      super(host, port, &method(:on_connection))
    end

    def on_connection(connection)
      while request = connection.request
        case request
        when Reel::Request
          route_request connection, request
        when Reel::WebSocket
          info "#{request.peeraddr[2]} connected"
          route_websocket request
        end
      end
    end

    def route_request(connection, request)
      if request.url == "/"
        return render_asset(connection, "index.html")
      elsif PUBLIC_FILES.include?(request.url.sub(/^\//, ''))
        return render_asset(connection, request.url)
      end

      info "404 Not Found: #{request.path}"
      connection.respond :not_found, "Not found"
    end

    def route_websocket(socket)
      if socket.url == "/clients"
        uuid = Celluloid.uuid
        proxy = Celluloid::MultiplexProxy.new(current_actor, uuid, :invoke)
        client = Client.new(proxy, socket)
        @clients[uuid] = ClientFacet.new(self, client)
      else
        info "Invalid WebSocket request for: #{socket.url}"
        socket.close
      end
    end

    def invoke(uuid, meth, *args, &block)
      @clients.fetch(uuid).__send__(meth, *args, &block)
    end

    def find_game(client)
      @waiting << client
      if @waiting.size == 2
        Game.new(@waiting)
        @waiting = []
      end
    end

    def render_asset(connection, path)
      info "200 OK: #{path}"
      connection.respond :ok, File.read(PUBLIC_ROOT.join(path.sub(/^\/+/, '')))
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)}>"
    end
  end
end
