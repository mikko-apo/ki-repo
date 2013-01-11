# encoding: UTF-8

# Copyright 2012 Mikko Apo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'socket'
require 'net/http'

require 'sinatra/base'
require 'sass'
require 'coffee-script'

module Ki

  class WebContext
    attr_accessor :ki_home
    attr_accessor :development
    attr_chain :started, -> { Time.now.to_i }
  end

  module KiWebBase
    def web_ctx
      RackCommand.web_ctx
    end

    def ki_home
      web_ctx.ki_home
    end

    def res_url(path)
      if path.include?("..")
        raise "File '#{path}' cannot reference parent directories with '..'!"
      end
      time = RackCommand.web_ctx.development ? Time.now.to_i : RackCommand.web_ctx.started
      "/file/web/#{time.to_s(16)}/#{self.class.name}:#{path}"
    end
  end

  # When starting up, looks for /web extension classes loaded from ki-scripts and starts up a web site
  #    class MyApp2 < Sinatra::Base
  #      get '/' do
  #        "MyApp2"
  #      end
  #    end
  #    KiCommand.register("/web/test", MyApp2)
  #
  # @see DefaultRackHandler
  class RackCommand
    @@web_ctx = WebContext.new

    attr_chain :shell_command, :require
    attr_chain :handler, -> { DefaultRackHandler }

    def ki_app
      extensions = KiCommand::KiExtensions.by_parent["/web"]
      if extensions.nil? || extensions.empty?
        raise "No /web extensions defined!"
      end
      RackCommand.build_app(extensions.map{|p,c| [p[4..-1], c]})
    end

    def RackCommand.build_app(path_class_list)
      Rack::Builder.new do
        path_class_list.each do |path, clazz|
          map(path) do
            run(clazz)
          end
        end
      end
    end

    def RackCommand.find_free_tcp_port
      socket = Socket.new(:INET, :STREAM, 0)
      socket.bind(Addrinfo.tcp("127.0.0.1", 0))
      begin
        socket.local_address.ip_port
      ensure
        socket.close
      end
    end

    def RackCommand.wait_until_url_responds(url, &block)
      try(20, 0.1) do
        response = Net::HTTP.get_response(URI(url))
        if block
          block.call(response)
        else
          if (code = response.code) == "200"
            return response
          else
            raise "Response code from #{url} was #{code}"
          end
        end
      end
    end

    def start_server
      @server = handler.new
      [:INT, :TERM].each { |sig| trap(sig) { @server.stop } }
      @server.run(ki_app, :Port => (@port || 8290))
    end

    def stop_server
      @server.stop
    end

    def execute(ctx, args)
      RackCommand.web_ctx.ki_home=ctx.ki_home
      @port = nil
      opts.parse(args)
      start_server
    end

    def opts
      OptionParser.new do |opts|
        opts.banner = ""
        opts.on("--handler HANDLER", "Use specified Rack Handler") do |v|
          handler(Object.const_get_full(v))
        end
        opts.on("--development", "Development mode, resource urls are reloaded") do |v|
          RackCommand.web_ctx.development=true
        end
        opts.on("-p", "--port PORT", "Use specified port") do |v|
          @port = Integer(v)
        end
      end
    end

    def self.web_ctx
      @@web_ctx
    end

    attr_chain :summary, -> { "Starts Ki web server and uses code from Ki packages" }

    def help
      <<EOF
ki-repo has a built in web server.

### Usage

    #{shell_command} - Starts Ki web server

### Parameters
#{opts}
EOF
    end
  end

  KiCommand.register_cmd("web", RackCommand)
end