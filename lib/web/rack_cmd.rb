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

require 'sinatra/base'

module Ki

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
    attr_chain :shell_command, :require
    attr_chain :handler, -> { DefaultRackHandler }

    def ki_app
      extensions = KiCommand::KiExtensions.by_parent["/web"]
      if extensions.nil? || extensions.empty?
        raise "No /web extensions defined!"
      end
      Rack::Builder.new do
        extensions.each do |path, clazz |
          web_path = path[4..-1]
          map(web_path) do
            run(clazz)
          end
        end
      end
    end

    def start_server
      handler.new.run(ki_app, :Port => (@port || 8290) )
    end

    def execute(ctx, args)
      @port = nil
      opts.parse(args)
      start_server
    end

    def opts
      OptionParser.new do |opts|
        opts.banner = ""
        opts.on("--handler HANDLER", "Use specified Rack Handler") do |v|
          handler(Object.const_get(v.to_sym))
        end
        opts.on("-p", "--port PORT", "Use specified port") do |v|
          @port = Integer(v)
        end
      end
    end

    attr_chain :summary, -> { "Starts Ki web server and uses code from Ki packages" }

    def help
<<EOF
ki-repo has a built in web server. It can be controlled with following commands
  #{shell_command}
EOF
    end
  end

  KiCommand.register_cmd("web", RackCommand)
end