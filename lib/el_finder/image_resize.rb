require 'shellwords'

module ElFinder

  class ImageResize

    def self.resize(pathname, options = {})
      return nil unless File.exist?(pathname)
      system( ::Shellwords.join(['mogrify', '-resize', "#{options[:width]}x#{options[:height]}", pathname.to_s]) ) 
    end # of self.resize

  end # of class ImageSize

end # of module ElFinder
