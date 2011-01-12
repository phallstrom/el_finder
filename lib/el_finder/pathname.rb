require 'fileutils'
require 'pathname'

module ElFinder

  class Pathname < ::Pathname

    #
    def +(other)
      self.class.new(super(other).to_s)
    end

    #
    def join(*args)
      self.class.new(super(*args).to_s)
    end

    #
    def rename(to)
      super(to)
    rescue Errno::EXDEV
      FileUtils.move(self.to_s, to.to_s)
      @path = to.to_s
    end # of rename

    #
    def self.new_with_root(root, path = '')
      path = path.to_s.sub(root, '') if path.to_s[0,1] == '/'
      new(superclass.new(File.join(root, path)).cleanpath.to_s)
    end # of self.new_with_root

    #
    def basename_without_extension
      basename(extname)
    end

    #
    def duplicate
      _dirname = dirname
      _extname = extname
      _basename = basename(_extname)
      copy = 0
      if _basename.to_s =~ /^(.*) copy (\d+)$/
        _basename = $1
        copy = $2.to_i
      end

      begin
        copy += 1
        new_file = self.class.superclass.new(_dirname + "#{_basename} copy #{copy}#{_extname}")
      end while new_file.exist?
      new_file
    end # of duplicate

    #
    def unique
      return self.dup unless self.file?

      _dirname = dirname
      _extname = extname
      _basename = basename(_extname)
      copy = 0

      begin
        copy += 1
        new_file = self.class.superclass.new(_dirname + "#{_basename} #{copy}#{_extname}")
      end while new_file.exist?
      new_file
    end # of unique

    #
    def relative_to(pathname)
      self == pathname ? '' : relative_path_from(pathname).to_s
    end # of relative_to

  end # of class Pathname

end # of module ElFinder
