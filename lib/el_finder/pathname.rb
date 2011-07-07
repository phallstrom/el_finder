require 'fileutils'
require 'pathname'

module ElFinder

  class Pathname
    attr_reader :root, :path

    #
    def initialize(root, path = '.')
      @root = root.is_a?(ElFinder::Pathname) ? root.root : ::Pathname.new(root)

      @path = ::Pathname.new(path) 
      @path = path.is_a?(ElFinder::Pathname) ? path.path : ::Pathname.new(path)
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
      @path.to_s == '.'
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
      self.class.new(@root, @path.dirname)
    end # of basename

    #
    def extname
      @path.nil? ? '' : @path.extname
    end # of extname

    #
    def to_s
      cleanpath.to_s
    end # of to_s
    alias_method :to_str, :to_s

    # We cheat and use the ::Pathname to keep this speedy.
    def child_directories(with_directory=true)
      @path.children(with_directory).select{ |child| child.directory? }.map{|e| self.class.new(@root, e)}
    end

    #
    def children(with_directory=true)
      realpath.children(with_directory).map{|e| self.class.new(@root, e)}
    end

    #
    def touch(options = {})
      FileUtils.touch(cleanpath, options)
    end

    #
    def relative_to(other)
      @path.relative_path_from(other)
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

    {
      'directory?' => {:path => 'realpath', :rescue => true                             },
      'exist?'     => {:path => 'realpath', :rescue => true                             },
      'file?'      => {:path => 'realpath', :rescue => true                             },
      'ftype'      => {:path => 'realpath',                                             },
      'mkdir'      => {:path => 'fullpath',                  :args => '(*args)'         },
      'mkdir'      => {:path => 'fullpath',                  :args => '(*args)'         },
      'mtime'      => {:path => 'realpath',                                             },
      'open'       => {:path => 'fullpath',                  :args => '(*args, &block)' },
      'read'       => {:path => 'fullpath',                  :args => '(*args)'         },
      'readlink'   => {:path => 'fullpath',                                             },
      'readable?'  => {:path => 'realpath', :rescue => true                             },
      'size'       => {:path => 'realpath',                                             },
      'symlink?'   => {:path => 'fullpath',                                             },
      'unlink'     => {:path => 'realpath',                                             },
      'writable?'  => {:path => 'realpath', :rescue => true                             },
    }.each_pair do |meth, opts|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{meth}#{opts[:args]}
          #{opts[:path]}.#{meth}#{opts[:args]}
        #{"rescue Errno::ENOENT\nfalse" if opts[:rescue]}
        end
      METHOD
    end


  end # of class Pathname

end # of module ElFinder
