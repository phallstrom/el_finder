require 'pathname'

module ElFinder

  class Pathname < ::Pathname

    def self.root=(pathname)
      pathname = superclass.new(pathname) if pathname.is_a?(String)
      @root = pathname
      @root = @root.cleanpath if @root.respond_to?(:cleanpath)
    end

    def self.root
      @root
    end

    def initialize(path)
      raise "ElFinder::Pathname requires a valid root" unless self.class.root.respond_to?(:directory?) && self.class.root.directory?

      path = self.class.superclass.new(path).cleanpath
      if path.absolute?
        super(self.class.root + path.to_s[1..-1])
      else
        super(self.class.root + path)
      end
    end

    def duplicate
      _dirname = dirname
      _extname = extname
      _basename = basename(_extname)
      copy = 0
      if _basename =~ /^(.*) copy ?(\d+)?$/
        _basename = $1
        copy = $2.to_i
      end

      begin
        copy += 1
        duplicate = self.class.superclass.new(_dirname + "#{_basename} copy #{copy}#{_extname}")
      end while duplicate.exist?
      duplicate
    end

  end # of class Pathname

end # of module ElFinder
