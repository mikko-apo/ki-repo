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