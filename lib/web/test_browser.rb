# encoding: UTF-8

# Copyright 2012-2013 Mikko Apo
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

require 'delegate'

module Ki

  class WebDriverDelegator < SimpleDelegator
    def errors
      []
    end

    def reset
      navigate.to "about:blank"
      manage.delete_all_cookies
    end
  end

  class FirefoxDelegator < WebDriverDelegator
    @@firefox = nil
    def FirefoxDelegator.init
      if @@firefox.nil?
        require "selenium-webdriver"
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile.add_extension File.join(File.dirname(__FILE__), "JSErrorCollector-0.5.xpi")
        @@firefox = FirefoxDelegator.new(Selenium::WebDriver.for(:firefox, :profile => profile))
        at_exit do
          @@firefox.quit
        end
      end
      @@firefox
    end

    def errors
# FF23 fails
#      execute_script("return window.JSErrorCollector_errors.pump()")
    end
  end

  class ChromeDelegator < WebDriverDelegator
    @@chrome = nil
    def ChromeDelegator.init
      if @@chrome.nil?
        require "selenium-webdriver"
        @@chrome = ChromeDelegator.new(Selenium::WebDriver.for(:chrome, :switches => %w[--ignore-certificate-errors --disable-popup-blocking --disable-translate]))
        at_exit do
          @@chrome.quit
        end
      end
      @@chrome
    end
  end
end