if RUBY_VERSION < '1.9'
  begin
    require 'base64'
  rescue LoadError
  end

  if defined? ::Base64
    module ::Base64
      def self.urlsafe_encode64(bin)
        [bin].pack("m0").tr("+/", "-_")
      end
      def self.urlsafe_decode64(str)
        str.tr("-_", "+/").unpack("m0").first
      end
    end
  end
end
