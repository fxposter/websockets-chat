$: << "#{File.dirname(__FILE__)}/../em-websocket/lib"
# require "rubygems"
require "em-websocket"

def current_time
  Time.now.strftime("%d/%m/%Y %H:%M:%S")
end

def format_message(username, message)
  "(#{current_time}) <strong>#{username}</strong>: #{message}"
end

def start_server(options = {})
  default_options = { :host => "localhost", :port => 8080, :debug => true }
  options = default_options.merge(options)
  
  EventMachine.run do
    @channel = EM::Channel.new
    @users = {}
    @last_messages = []
  
    EventMachine::WebSocket.start(options) do |ws|
      ws.onopen do
        @users[ws.object_id] = @channel.subscribe { |msg| ws.send msg }
  
        @last_messages.each do |message|
          ws.send message
        end
  
        @channel.push "#{ws.request["Query"]["username"]} connected!"
      end
  
      ws.onmessage do |msg|
        message = format_message(ws.request["Query"]["username"], msg)
        @last_messages << message
        @last_messages.shift if (@last_messages.length > 10) 
  
        @channel.push message
      end
  
      ws.onclose do
        @channel.unsubscribe(@users[ws.object_id])
        @channel.push "#{ws.request["Query"]["username"]} disconnected!"
        @users.delete(ws.object_id)
      end
    end
  
    puts "Server started with options: #{options.inspect}"
  end
end

options = {}
options[:host] = ARGV[0] if ARGV.length > 0
options[:port] = ARGV[1].to_i if ARGV.length > 1
options[:debug] = (ARGV[2] == "true") if ARGV.length > 2

start_server(options)
