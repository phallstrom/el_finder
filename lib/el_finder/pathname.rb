require 'fileutils'
require 'pathname'

module ElFinder

  class Pathname
    attr_reader :root, :path

    #
    def initialize(root, path = '')
      @root = root.is_a?(Pathname) ? root : ::Pathname.new(root)

      @path = ::Pathname.new(path) 
      @path = path.is_a?(Pathname) ? path : ::Pathname.new(path)
      if absolute?
        if @path.cleanpath.to_s.start_with?(@root.to_s)
          @path = ::Pathname.new @path.to_s.slice((@root.to_s.length + 1)..-1)
        elsif @path.cleanpath.to_s.start_with?(@root.realpath.to_s)
          @path = ::Pathname.new @path.to_s.slice((@root.realpath.to_s.length + 1)..-1)
        else
          raise SecurityError, "Absolute paths are not allowed" 
        end
      end
      raise SecurityError, "Paths outside the root are not allowed" if outside_of_root?

    end # of initialize
    
    #
    def +(other)
      if other.is_a? ::ElFinder::Pathname
        other = other.path
      end
      self.class.new(@root, (@path + other).to_s)
    end # of +

    #
    def is_root?
      @path.to_s.empty?
    end

    #
    def absolute?
      @path.absolute?
    end # of absolute?

    #
    def relative?
      @path.relative?
    end # of relative?

    #
    def outside_of_root?
      !cleanpath.to_s.start_with?(@root.to_s)
    end # of outside_of_root?

    #
    def fullpath
      @path.nil? ? @root : @root + @path
    end # of fullpath

    #
    def cleanpath
      fullpath.cleanpath
    end # of cleanpath

    #
    def realpath
      fullpath.realpath
    end # of realpath

    #
    def basename(*args)
      @path.basename(*args)
    end # of basename

    #
    def basename_sans_extension
      @path.basename(@path.extname)
    end # of basename

    #
    def basename(*args)
      @path.basename(*args)
    end # of basename

    #
    def dirname
      @path.dirname
    end # of basename

    #
    def extname
      @path.nil? ? '' : @path.extname
    end # of extname

    #
    def to_s
      @path.to_s
    end # of to_s

    #
    def children(with_directory=true)
      realpath.children(with_directory).map{|e| self.class.new(@root, e)}
    end

    #
    def touch(options = {})
      FileUtils.touch(cleanpath, options)
    end
    
    #
    def unique
      return self.dup unless self.file?
      copy = 1
      begin
        new_file = self.class.new(@root, dirname + "#{basename_sans_extension} #{copy}#{extname}")
        copy += 1
      end while new_file.exist?
      new_file
    end # of unique

    #
    def duplicate
      _basename = basename_sans_extension
      copy = 1
      if _basename.to_s =~ /^(.*) copy (\d+)$/
        _basename = $1
        copy = $2.to_i
      end
      begin
        new_file = self.class.new(@root, dirname + "#{_basename} copy #{copy}#{extname}")
        copy += 1
      end while new_file.exist?
      new_file
    end # of duplicate

    #
    def rename(to)
      to = self.class.new(@root, to.to_s)
      realpath.rename(to.fullpath.to_s)
    rescue Errno::EXDEV
      FileUtils.move(realpath.to_s, to.fullpath.to_s)
    ensure
      @path = to.path
    end # of rename

    %w(
      directory? 
      exist? 
      file? 
      readable? 
      writable?
    ).each do |meth|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{meth}
          realpath.#{meth}
        rescue Errno::ENOENT
          false
        end
      METHOD
    end

    %w(
      mtime
      unlink
    ).each do |meth|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{meth}
          realpath.#{meth}
        end
      METHOD
    end

    %w(
      mkdir
      read
    ).each do |meth|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{meth}(*args)
          fullpath.#{meth}(*args)
        end
      METHOD
    end

    %w(
      open
    ).each do |meth|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{meth}(*args, &block)
          fullpath.#{meth}(*args, &block)
        end
      METHOD
    end


  end # of class Pathname

end # of module ElFinder
