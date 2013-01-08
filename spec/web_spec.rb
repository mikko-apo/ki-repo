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

require 'spec_helper'

class MyApp2 < Sinatra::Base
  get '/' do
    "MyApp2"
  end
end

require 'socket'
def find_free_tcp_port
  socket = Socket.new(:INET, :STREAM, 0)
  socket.bind(Addrinfo.tcp("127.0.0.1", 0))
  begin
    socket.local_address.ip_port
  ensure
    socket.close
  end
end

require 'net/http'
def http_get(url)
  Net::HTTP.get_response(URI(url))
end

require 'spec_helper'

describe RackCommand do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "DefaultRackHandler should create rack handler" do
    port = find_free_tcp_port
    rack = DefaultRackHandler.new
    Thread.new do
      rack.run(MyApp2, :Port => port)
    end
    @tester.catch_stdio do
      try(20, 0.1) do
        response = http_get(File.join("http://localhost:#{port}"))
        [response.code, response.body].should eq ["200", "MyApp2"]
      end
    end.stderr.join("\n").should =~/#{port}/
    rack.stop
  end

  it "DefaultRackHandler should warn if no handlers found" do
    Rack::Handler.expects(:get).times(3).raises("foo")
    lambda { DefaultRackHandler.new.run(MyApp2, :Port => 12333) }.should raise_error("Could not resolve server handlers for any of 'thin, mongrel, webrick'.")
  end

  it "should start web app with registered classes" do
    restore_extensions
    KiCommand.register("/web/test", MyApp2)
    port = find_free_tcp_port
    DefaultRackHandler.any_instance.expects(:run).times(2).with do |app, config|
      config.should eq({:Port => port})
      code, headers, html = app.call("PATH_INFO" => "/test", "SCRIPT_NAME" => "test", "rack.input" => "1", "REQUEST_METHOD" => "GET")
      [code, html.first].should eq [200, "MyApp2"]
      true
    end
    KiCommand.new.execute(%W(web -p #{port}))
    KiCommand.new.execute(%W(web -p #{port} --handler DefaultRackHandler))
  end

  it "KiWebBase should provide helper methods" do
    a = "testObject"
    a.extend KiWebBase
    a.ki_home.path.should eq Dir.pwd
    Time.expects(:now).returns 123
    a.res_url("foo.scss").should eq "/file/web/123/String:foo.scss"
    lambda{a.res_url("../foo.scss")}.should raise_error("File '../foo.scss' cannot reference parent directories with '..'!")
  end

  it "should warn if no web extensions registered" do
    lambda { KiCommand.new.execute(%W(web)) }.should raise_error("No /web extensions defined!")
  end

  it "should print help" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "web"])
    end.stdout.join.should =~ /web server/
  end
end
