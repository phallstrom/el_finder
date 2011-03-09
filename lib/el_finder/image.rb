require 'rubygems'
require 'shellwords'
require 'image_size'

module ElFinder

  class Image

    def self.size(pathname)
      return nil unless File.exist?(pathname)
      s = ::ImageSize.new(File.open(pathname)).size.to_s
      s = nil if s.empty?
      return s
    end

    def self.resize(pathname, options = {})
      return nil unless File.exist?(pathname)
      system( ::Shellwords.join(['mogrify', '-resize', "#{options[:width]}x#{options[:height]}!", pathname.to_s]) ) 
    end # of self.resize

    def self.thumbnail(src, dst, options = {})
      return nil unless File.exist?(src)
      system( ::Shellwords.join(['convert', '-resize', "#{options[:width]}x#{options[:height]}", '-background', 'white', '-gravity', 'center', '-extent', "#{options[:width]}x#{options[:height]}", src.to_s, dst.to_s]) ) 
    end # of self.resize

  end # of class Image

end # of module ElFinder
