require_relative '../../app/services/server'

namespace :tcp_server do
  desc "Start the TCP server"
  task start: :environment do
    server = TcpServer.new(1234)
    server.start  
  end
end
