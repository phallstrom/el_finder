module ElFinder
  class Connector
    
    VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open paste ping read rename resize rm tmb upload]

    DEFAULT_OPTIONS = {
      :mime_handler => ElFinder::MimeType,
      :disabled_commands => [],
      :show_dot_files => true,
      :upload_max_size => '50M',
      :archivers => [],
      :extractors => [],
      :home => 'Home',
    }

    #
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)

      raise(RuntimeError, "Missing required :url option") unless @options.key?(:url) 
      raise(RuntimeError, "Missing required :root option") unless @options.key?(:root) 

      @mime_handler = @options.delete(:mime_handler)
      raise(RuntimeError, "Mime Handler is invalid") unless @mime_handler.respond_to?(:for)

      @root = ElFinder::Pathname.new(options[:root])

      @headers = {}
      @response = {}
    end # of initialize

    #
    def run(params = {})
      @params = params.dup

      if VALID_COMMANDS.include?(@params[:cmd])

        @current = from_hash(@params[:current]) if @params[:current]
        @target = from_hash(@params[:target]) if @params[:target]
        if params[:targets]
          @targets = @params[:targets].map{|t| from_hash(t)}
        end

        send("_#{@params[:cmd]}")
      else
        invalid_request
      end

      return @headers, @response
    end # of run

    #
    def to_hash(pathname)
      pathname == @root ? '/' : pathname.relative_to(@root).to_s
    end # of to_hash

    #
    def from_hash(hash)
      if hash == '/' || hash.blank?
        pathname = @root.dup
      else
        pathname = ElFinder::Pathname.new_with_root(@root, hash)
      end
    end # of from_hash

    ################################################################################
    protected

    #
    def _open(target = nil)
      target ||= @target

      if target.file?
        command_not_implemented
      elsif target.directory?
        @response[:cwd] = cwd_for(target)
        @response[:cdc] = target.children.map{|e| cdc_for(e)}

        if @params[:tree]
          @response[:tree] = {
            :name => @options[:home],
            :hash => to_hash(@root),
            :read => @root.readable?,              
            :write => @root.writable?,            
            :dirs => tree_for(@root)
          }
        end

        if @params[:init]
          @response[:disabled] = @options[:disabled_commands]
          @response[:params] = {
            :dotFiles => @options[:show_dot_files],
            :uplMaxSize => @options[:upload_max_size],
            :archives => @options[:archivers],
            :extract => @options[:extractors],
            :url => @options[:url]
          }
        end

        # FIXME - add 'tmb:true' when necessary
        
      else
        @response[:error] = "Directory does not exist"
        _open(@root)
      end

    end # of open

    #
    def _mkdir
      dir = @current + @params[:name]
      if dir.mkdir
        @params[:tree] = true
        @response[:select] = [to_hash(dir)]
        _open(@current)
      else
        @response[:error] = "Unable to create folder"
      end
    end # of mkdir

    #
    def _mkfile
      file = @current + @params[:name]
      if FileUtils.touch(file)
        @response[:select] = [to_hash(file)]
        _open(@current)
      else
        @response[:error] = "Unable to create file"
      end
    end # of mkfile

    #
    def _rename
      to = @current + @params[:name]
      if to.exist?
        @response[:error] = "Unable to rename #{@target.ftype}. '#{to.basename}' already exists"
      elsif @target.rename(to)
        @params[:tree] = to.directory?
        @response[:select] = [to_hash(to)]
        _open(@current)
      else
        @response[:error] = "Unable to rename #{@target.ftype}"
      end
    end # of rename

    #
    def _upload
      select = []
      @params[:upload].to_a.each do |file|
        dst = @current + file.original_filename
        File.rename(file.path, dst)
        select << to_hash(dst)
      end
      @response[:select] = select
      _open(@current)
    end # of upload

    #
    def _ping
      @headers['Connection'] = 'Close'
    end # of ping

    #
    def _paste
      @targets.to_a.each do |src|
        dst = from_hash(@params[:dst]) + src.basename
        if @params[:cut].to_i > 0
          File.rename(src, dst)
        else
          FileUtils.copy(src, dst)
        end
      end
      @params[:tree] = true
      _open(@current)
    end # of paste

    #
    def _rm
      if @targets.empty?
        @response[:error] = "No files were selected for removal"
      else
        FileUtils.rm_rf(@targets)
        @params[:tree] = true
        _open(@current)
      end
    end # of rm

    #
    def _duplicate
      duplicate = @target.duplicate
      if @target.directory?
        FileUtils.cp_r(@target, duplicate)
      else
        FileUtils.copy(@target, duplicate)
      end
      @response[:select] = [duplicate]
      _open(@current)
    end # of duplicate

    # 
    def _read
      @response[:content] = @target.read
    end # of read

    #
    def _edit
      @target.open('w') { |f| f.puts @params[:content] }
      @response[:file] = cdc_for(@target)
    end # of edit

    #
    def _extract
      command_not_implemented
    end # of extract

    #
    def _archive
      command_not_implemented
    end # of archive

    #
    def _tmb
      command_not_implemented
    end # of tmb

    #
    def _resize
      command_not_implemented
      # system("mogrify -resize '#{@params[:width].to_i}x#{@params[:height].to_i}' '#{@target.to_s}'")
      # _open(@current).merge(:select => [@target])
    end # of resize
    
    ################################################################################
    private

    # 
    def cwd_for(pathname)
      {
        :name => pathname.basename.to_s,
        :hash => to_hash(pathname),
        :mime => 'directory',
        :rel => (@options[:home] + '/' + pathname.relative_to(@root)),
        :size => 0,
        :date => pathname.mtime.to_s,
        :read => pathname.readable?,
        :write => pathname.writable?,
        :rm => (pathname != @root && pathname.writable?),
      }
    end

    # TODO - Implement link, linkTo, and parent
    def cdc_for(pathname)
      response = {
        :name => pathname.basename.to_s,
        :hash => to_hash(pathname),
        :date => pathname.mtime.to_s,
        :read => pathname.readable?,
        :write => pathname.writable?,
        :rm => pathname.writable?,
      }

      if pathname.directory?
        response.merge!(
          :size => 0,
          :mime => 'directory'
        )
      elsif pathname.symlink?
        response.merge!(
          :link => 'FIXME',
          :linkTo => 'FIXME',
          :parent => 'FIXME'
        )
      elsif pathname.file?
        # FIXME - resize, dim, url
        # identify -format '%wx%h' '#{pathname.to_s}'
        response.merge!(
          :size => pathname.size, 
          :mime => @mime_handler.for(pathname),
          :url => (@options[:url] + '/' + pathname.relative_path_from(@root))
        )
      end

      return response
    end

    #
    def tree_for(root)
      root.children.select{ |child| child.directory? }.sort_by{|e| e.basename.to_s.downcase}.map { |child|
        {:name => child.basename.to_s,
         :hash => to_hash(child),
         :read => child.readable?,
         :write => child.writable?,
         :dirs => tree_for(child),
        }
      }
    end # of tree_for
    
    #
    def invalid_request
      @response[:error] = "Invalid command '#{@params[:cmd]}'"
    end # of invalid_request

    #
    def command_not_implemented
      @response[:error] = "Command '#{@params[:cmd]}' not yet implemented"
    end # of command_not_implemented

  end # of class Connector
end # of module ElFinder
