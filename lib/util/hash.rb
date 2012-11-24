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