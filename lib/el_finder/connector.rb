module ElFinder
  class Connector
    
    VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open paste ping read rename resize rm tmb upload]

    DEFAULT_OPTIONS = {
      :mime_handler => ElFinder::MimeType,
      :debug => true,
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
      raise(RuntimeError, "Mime Handler is invalid") unless @mime_handler.respond_to?(:for_pathname)

      @root = ElFinder::Pathname.root = @options[:root]

      @headers = {}
      @response = {}
    end # of initialize

    #
    def run(params = {})
      @params = params.dup

      if VALID_COMMANDS.include?(@params[:cmd])

        @current = ElFinder::Pathname.new(@params[:current]) if @params[:current]
        @target = ElFinder::Pathname.new(@params[:target]) if @params[:target]
        if params[:targets]
          @targets = @params[:targets].map{|t| ElFinder::Pathname.new(t)}
        end

        send("_#{@params[:cmd]}")
      else
        invalid_request
      end

      @response[:debug] = @params if @options[:debug]

      return @headers, @response
    end # of run

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
            :hash => @root.hash,
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
        
      else
        @response[:error] = "Directory does not exist"
        _open(@root)
      end

    end # of open

    #
    def _mkdir
    end # of mkdir

    #
    def _mkfile
    end # of mkfile

    #
    def _rename
    end # of rename

    #
    def _upload
    end # of upload

    #
    def _ping
    end # of ping

    #
    def _paste
    end # of paste

    #
    def _rm
    end # of rm

    #
    def _duplicate
    end # of duplicate

    #
    def _read
    end # of read

    #
    def _edit
    end # of edit

    #
    def _extract
    end # of extract

    #
    def _archive
    end # of archive

    #
    def _tmb
    end # of tmb

    #
    def _resize
    end # of resize
    
    ################################################################################
    private

    # 
    def cwd_for(pathname)
      {
        :name => pathname.basename.to_s,
        :hash => pathname.hash,
        :mime => 'directory',
        :rel => (@options[:home] + pathname.relative_to_root),
        :size => 0,
        :date => pathname.mtime.to_s,
        :read => pathname.readable?,
        :write => pathname.writable?,
        :rm => !pathname.is_root? && pathname.writable?,
      }
    end

    # TODO - Implement link, linkTo, and parent
    def cdc_for(pathname)
      response = {
        :name => pathname.basename.to_s,
        :hash => pathname.hash,
        :date => pathname.mtime.to_s,
        :read => pathname.readable?,
        :write => pathname.writable?,
        :rm => pathname.writable?,
      }

      if pathname.directory?
        response.merge!(:size => 0)
      elsif pathname.symlink?
        response.merge!(
          :link => 'FIXME',
          :linkTo => 'FIXME',
          :parent => 'FIXME'
        )
      elsif pathname.file?
        response.merge!(
          :size => pathname.size, 
          :mime => @mime_handler.for_pathname(pathname),
          :url => (@options[:url] + '/' + pathname.relative_to_root)
        )
      end

      return response
    end

    #
    def tree_for(root)
      root.children.select{ |child| child.directory? }.sort_by{|e| e.basename.to_s.downcase}.map { |child|
        {:name => child.basename.to_s,
         :hash => child.hash,
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
