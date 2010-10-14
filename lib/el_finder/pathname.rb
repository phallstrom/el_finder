require 'pathname'

module ElFinder

  class Pathname < ::Pathname

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
        duplicate = Pathname.new(_dirname + "#{_basename} copy #{copy}#{_extname}")
      end while duplicate.exist?
      duplicate
    end

  end # of class Pathname

end # of module ElFinder
