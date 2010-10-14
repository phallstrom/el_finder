module ElFinder
  class Connector
    
    VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open paste ping read rename resize rm tmb upload]

    DEFAULT_OPTIONS = {
      :mime_handler => ElFinder::MimeType,
      :debug => true
    }

    #
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      raise(RuntimeError, "Missing required :root option") unless @options.key?(:root) 
      raise(RuntimeError, "Missing required :url option") unless @options.key?(:url) 

      @mime_handler = @options.delete(:mime_handler)
      raise(RuntimeError, "Mime Handler is invalid") unless @mime_handler.respond_to?(:for_pathname)

      @headers = {}
      @response = {}
    end # of initialize

    #
    def run(params = {})
      @params = params.dup

      if VALID_COMMANDS.include?(@params[:cmd])
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
    def _open
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

