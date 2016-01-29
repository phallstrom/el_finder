require 'rubygems'
require 'shellwords'
require 'image_size'

module ElFinder

  # Represents default image handler.
  # It uses *mogrify* to resize images and *convert* to create thumbnails.
  class Image

    def self.size(pathname)
      return nil unless File.exist?(pathname)
      s = ::ImageSize.path(pathname).size.to_s
      s = nil if s.empty?
      return s
    rescue
      nil
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
