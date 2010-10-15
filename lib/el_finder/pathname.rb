require 'pathname'

module ElFinder

  class Pathname < ::Pathname

    #
    def self.root=(pathname)
      pathname = superclass.new(pathname) if pathname.is_a?(String)
      @root = pathname
      @root = @root.cleanpath if @root.respond_to?(:cleanpath)
    end # of self.root=

    #
    def self.root
      @root
    end # of self.root

    #
    def initialize(path)
      raise "ElFinder::Pathname requires a valid root" unless self.class.root.respond_to?(:directory?) && self.class.root.directory?

      path = self.class.superclass.new(path).cleanpath
      if path.absolute?
        super(self.class.root + path.to_s[1..-1])
      else
        super(self.class.root + path)
      end
    end # of initialize

    #
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
    end # of duplicate

    #
    def relative_to_root
      self.to_s.sub(%r!^#{self.class.root}/?!, '')
    end # of relative_to_root

    #
    def hash
      relative_to_root.to_s
    end # of hash

    #
    def self.new_from_hash(path)
      new(path)
    end # of self.new_from_hash

    #
    def is_root?
      relative_to_root.empty?
    end # of is_root?


  end # of class Pathname

end # of module ElFinder
