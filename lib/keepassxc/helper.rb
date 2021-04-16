module KeepassXC
  module Helper
    def to_b64(string)
      [string].pack('m*').chomp
    end

    def from_b64(string)
      string.unpack1('m*')
    end
  end
end
