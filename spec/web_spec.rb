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

class BrokenJsApp < Sinatra::Base
  get "/" do
    '<html><body>BrokenJsApp.txt<script type="text/javascript">al();</script></body></html>'
  end
end

require 'spec_helper'

describe RackCommand do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    RackCommand.web_ctx.development=nil
    @tester.after
  end

  it "DefaultRackHandler should create rack handler" do
    port = RackCommand.find_free_tcp_port
    rack = DefaultRackHandler.new
    @tester.catch_stdio do
      Thread.new do
        rack.run(MyApp2, :Port => port)
      end
      RackCommand.wait_until_url_responds("http://localhost:#{port}") do |response|
        [response.code, response.body].should eq ["200", "MyApp2"]
      end
      rack.stop
    end.stderr.join("\n").should =~/#{port}/
  end

  it "DefaultRackHandler should warn if no handlers found" do
    Rack::Handler.expects(:get).times(3).raises("foo")
    lambda { DefaultRackHandler.new.run(MyApp2, :Port => 12333) }.should raise_error("Could not resolve server handlers for any of 'thin, mongrel, webrick'.")
  end

  it "should start web app with registered classes" do
    @tester.restore_extensions
    KiCommand.register("/web/test", MyApp2)
    port = RackCommand.find_free_tcp_port
    # mocking run prevents web app from blocking
    DefaultRackHandler.any_instance.expects(:run).times(2).with do |app, config|
      config.should eq({:Port => port})
      code, headers, html = app.call("PATH_INFO" => "/test", "SCRIPT_NAME" => "test", "rack.input" => "1", "REQUEST_METHOD" => "GET")
      [code, html.body.first].should eq [200, "MyApp2"]
      true
    end
    KiCommand.new.execute(%W(web -p #{port}))
    KiCommand.new.execute(%W(web -p #{port} --handler DefaultRackHandler --development))
  end

  it "KiWebBase should provide helper methods" do
    a = "testObject"
    a.extend KiWebBase
    a.ki_home.path.should eq Dir.pwd

    # production mode caches time
    Time.expects(:now).returns 123
    a.res_url("foo.scss").should eq "/file/web/7b/String:foo.scss"
    a.res_url("foo.scss").should eq "/file/web/7b/String:foo.scss"
    RackCommand.web_ctx.development=true
    a.res_url("foo.scss").should eq "/file/web/7b/String:foo.scss"
    lambda { a.res_url("../foo.scss") }.should raise_error("File '../foo.scss' cannot reference parent directories with '..'!")
  end

  it "should warn if no web extensions registered" do
    lambda { KiCommand.new.execute(%W(web)) }.should raise_error("No /web extensions defined!")
  end

  it "should print help" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "web"])
    end.stdout.join.should =~ /web server/
  end

  it "supports launching web site from tests" do
    @tester.restore_extensions
    KiCommand.register("/web/test", MyApp2)

    RackCommand.web_ctx.ki_home=KiHome.new(@tester.tmpdir)
    port = RackCommand.find_free_tcp_port
    rack_command = RackCommand.new
    url = "http://localhost:#{port}/test"
    @tester.cleaners << -> {rack_command.stop_server}
    @tester.catch_stdio do
      Thread.new do
        rack_command.execute(RackCommand.web_ctx, %W(-p #{port}))
      end
      RackCommand.wait_until_url_responds(url) do |response|
        [response.code, response.body].should eq ["200", "MyApp2"]
      end
    end
  end

  describe "helper method wait_until_url_responds" do
    it "should return when socket responds" do
      url = "foo"
      seq = sequence('requests')
      ok = mock
      ok.expects(:code).returns("200")
      fail = mock
      fail.expects(:code).returns("501")
      Net::HTTP.expects(:get_response).with(URI(url)).raises("error").in_sequence(seq)
      Net::HTTP.expects(:get_response).with(URI(url)).returns(fail).in_sequence(seq)
      Net::HTTP.expects(:get_response).with(URI(url)).returns(ok).in_sequence(seq)
      RackCommand.wait_until_url_responds("foo")
    end
  end
end

describe WebDriverDelegator do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should open browser and collect js errors" do
    port = RackCommand.find_free_tcp_port
    rack = DefaultRackHandler.new
    @tester.cleaners << -> {rack.stop}

    firefox = FirefoxDelegator.init

    chrome = ChromeDelegator.init

    url = "http://localhost:#{port}"
    @tester.catch_stdio do
      Thread.new do
        rack.run(BrokenJsApp, :Port => port)
      end
      RackCommand.wait_until_url_responds(url) do |response|
        response.code.should eq "200"
        response.body.should =~ /BrokenJsApp.txt/
      end
    end.stderr.join("\n").should =~/#{port}/

    firefox.navigate.to url
    firefox.find_element(:tag_name => "body").text.should eq "BrokenJsApp.txt"
    firefox.errors.should eq [{"errorMessage"=>"ReferenceError: al is not defined", "sourceName"=>"http://localhost:#{port}/", "lineNumber"=>1, "__fxdriver_unwrapped"=>true}]
    firefox.reset
    firefox.current_url.should eq "about:blank"

    chrome.navigate.to url
    chrome.find_element(:tag_name => "body").text.should eq "BrokenJsApp.txt"
    chrome.errors.should eq []
    chrome.reset
    chrome.current_url.should eq "about:blank"
  end

end
