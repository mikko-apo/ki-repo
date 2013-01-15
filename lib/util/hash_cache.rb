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
# Caching Hash, resolves values at request time
  class HashCache < Hash
    # If key has not been defined, uses block to resolve the value. Value is stored and returned
    # @param key Key
    # @param [Proc] block Block which is evaluated if the key does not have value yet. Block's value is stored to hash
    # @return Existing value or one resolved with the block
    def cache(key, &block)
      if !include?(key)
        store(key, block.call)
      end
      self[key]
    end
  end
end