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

# Uses JSErrorCollector by mguillem from https://github.com/mguillem/JSErrorCollector
# Uses code by Gabe Kopley from https://gist.github.com/1371962

module Ki
  class TestBrowser
    attr_reader :driver
    @driver = nil

    def initialize
      require "selenium-webdriver"
    end

    def driver
      if @driver.nil?
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile.add_extension File.join(File.dirname(__FILE__), "JSErrorCollector-0.4.xpi")
        @driver = Selenium::WebDriver.for :firefox, :profile => profile
      end
      @driver
    end

    def errors
      @driver.execute_script("return window.JSErrorCollector_errors.pump()")
    end

    def quit
      @driver.quit
    end
  end
end