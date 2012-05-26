if RUBY_VERSION < '1.9'
  begin
    require 'base64'
  rescue LoadError
  end

  if defined? ::Base64
    # The Base64 module provides for the encoding (encode64, strict_encode64, urlsafe_encode64) and decoding (decode64, strict_decode64, urlsafe_decode64) of binary data using a Base64 representation.
    # @note stdlib module.
    module ::Base64
      # Returns the Base64-encoded version of bin. This method complies with "Base 64 Encoding with URL and Filename Safe Alphabet" in RFC 4648. The alphabet uses '-' instead of '+' and '_' instead of '/'.
      # @note This method will be defined only on ruby 1.8 due to its absence in stdlib.
      def self.urlsafe_encode64(bin)
        [bin].pack("m0").tr("+/", "-_")
      end

      # Returns the Base64-decoded version of str. This method complies with "Base 64 Encoding with URL and Filename Safe Alphabet" in RFC 4648. The alphabet uses '-' instead of '+' and '_' instead of '/'.
      # @note This method will be defined only on ruby 1.8 due to its absence in stdlib.
      def self.urlsafe_decode64(str)
        str.tr("-_", "+/").unpack("m0").first
      end
    end
  end
end
