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

module Ki

  class WebUtil
    def WebUtil.find_free_tcp_port
      socket = Socket.new(:INET, :STREAM, 0)
      socket.bind(Addrinfo.tcp("127.0.0.1", 0))
      begin
        socket.local_address.ip_port
      ensure
        socket.close
      end
    end

    def WebUtil.wait_until_url_responds(url, &block)
      try(20, 0.1) do
        response = get(url)
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

    def self.get(url)
      Net::HTTP.get_response(URI(url))
    end
  end
end