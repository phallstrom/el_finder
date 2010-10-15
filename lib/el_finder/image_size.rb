require 'rubygems'
require 'image_size'

module ElFinder

  class ImageSize < ::ImageSize

    def self.for(pathname)
      return nil unless File.exist?(pathname)
      s = new(File.open(pathname)).get_size.join('x').to_s
      s = nil if s == 'x'
      return s
    end

  end # of class ImageSize

end # of module ElFinder
