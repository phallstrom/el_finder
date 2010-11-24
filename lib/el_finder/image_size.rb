require 'rubygems'
require 'image_size'

module ElFinder

  class ImageSize < ::ImageSize

    def self.for(pathname)
      return nil unless File.exist?(pathname)
      s = new(File.open(pathname)).size.to_s
      s = nil if s.empty?
      return s
    end

  end # of class ImageSize

end # of module ElFinder
