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

require 'digest/sha1'
require 'digest/sha2'
require 'digest/md5'

module Ki

# SHA1, uses standard Ruby library
  class SHA1
    # SHA1, uses standard Ruby library
    def SHA1.digest
      Digest::SHA1.new
    end
  end

# SHA2, uses standard Ruby library
  class SHA2
    # SHA2, uses standard Ruby library
    def SHA2.digest
      Digest::SHA2.new
    end
  end

# MD5, uses standard Ruby library
  class MD5
    # MD5, uses standard Ruby library
    def MD5.digest
      Digest::MD5.new
    end
  end
end