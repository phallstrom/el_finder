require 'base64'

module ElFinder
  class Connector
    
    VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open paste ping read rename resize rm tmb upload]

    DEFAULT_OPTIONS = {
      :mime_handler => ElFinder::MimeType,
      :image_size_handler => ElFinder::ImageSize,
      :image_resize_handler => ElFinder::ImageResize,
      :original_filename_method => lambda {|file| file.original_filename},
      :disabled_commands => [],
      :show_dot_files => true,
      :upload_max_size => '50M',
      :archivers => [],
      :extractors => [],
      :home => 'Home',
      :default_perms => {:read => true, :write => true, :rm => true},
      :perms => []
    }

    #
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)

      raise(RuntimeError, "Missing required :url option") unless @options.key?(:url) 
      raise(RuntimeError, "Missing required :root option") unless @options.key?(:root) 
      raise(RuntimeError, "Mime Handler is invalid") unless mime_handler.respond_to?(:for)
      raise(RuntimeError, "Image Size Handler is invalid") unless image_size_handler.nil? || image_size_handler.respond_to?(:for)
      raise(RuntimeError, "Image Resize Handler is invalid") unless image_resize_handler.nil? || image_resize_handler.respond_to?(:resize)

      @root = ElFinder::Pathname.new(options[:root])

      @headers = {}
      @response = {}
    end # of initialize

    #
    def run(params = {})
      @params = params.dup
      @response[:errorData] = {}

      if VALID_COMMANDS.include?(@params[:cmd])

        @current = @params[:current] ? from_hash(@params[:current]) : nil
        @target = @params[:target] ? from_hash(@params[:target]) : nil
        if params[:targets]
          @targets = @params[:targets].map{|t| from_hash(t)}
        end



        send("_#{@params[:cmd]}")
      else
        invalid_request
      end

      @response.delete(:errorData) if @response[:errorData].empty?

      return @headers, @response
    end # of run

    #
    def to_hash(pathname)
      Base64.encode64(pathname == @root ? '/' : pathname.relative_path_from(@root).to_s).chomp
    end # of to_hash

    #
    def from_hash(hash)
      pathname = ElFinder::Pathname.new_with_root(@root, Base64.decode64(hash))
    end # of from_hash

    #
    def options=(opts = {})
      opts.each_pair do |k,v|
        @options[k.to_sym] = v
      end
    end

    ################################################################################
    protected

    #
    def _open(target = nil)
      target ||= @target

      if target.nil?
        _open(@root)
        return
      end

      if perms_for(target)[:read] == false
        @response[:error] = 'Access Denied'
        return
      end

      if target.file?
        command_not_implemented
      elsif target.directory?
        @response[:cwd] = cwd_for(target)
        @response[:cdc] = target.children.map{|e| cdc_for(e)}

        if @params[:tree]
          @response[:tree] = {
            :name => @options[:home],
            :hash => to_hash(@root),
            :dirs => tree_for(@root),
          }.merge(perms_for(@root))
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
      if perms_for(@current)[:write] == false
        @response[:error] = 'Access Denied'
        return
      end

      dir = @current + @params[:name]
      if !dir.exist? && dir.mkdir
        @params[:tree] = true
        @response[:select] = [to_hash(dir)]
        _open(@current)
      else
        @response[:error] = "Unable to create folder"
      end
    end # of mkdir

    #
    def _mkfile
      if perms_for(@current)[:write] == false
        @response[:error] = 'Access Denied'
        return
      end

      file = @current + @params[:name]
      if !file.exist? && FileUtils.touch(file)
        @response[:select] = [to_hash(file)]
        _open(@current)
      else
        @response[:error] = "Unable to create file"
      end
    end # of mkfile

    #
    def _rename
      to = @current + @params[:name]

      perms_for_target = perms_for(@target)
      if perms_for_target[:rm] == false
        @response[:error] = 'Access Denied'
        return
      end

      perms_for_current = perms_for(@current)
      if perms_for_current[:write] == false
        @response[:error] = 'Access Denied'
        return
      end

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
      if perms_for(@current)[:write] == false
        @response[:error] = 'Access Denied'
        return
      end

      select = []
      @params[:upload].to_a.each do |file|
        dst = @current + @options[:original_filename_method].call(file)
        FileUtils.mv(file.path, dst)
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
      if perms_for(from_hash(@params[:dst]))[:write] == false
        @response[:error] = 'Access Denied'
        return
      end

      @targets.to_a.each do |src|
        if perms_for(src)[:read] == false || (@params[:cut].to_i > 0 && perms_for(src)[:rm] == false)
          @response[:error] ||= 'Some files were not copied.'
          @response[:errorData][src.basename.to_s] = "Access Denied"
          return
        else
          dst = from_hash(@params[:dst]) + src.basename
          if dst.exist?
            @response[:error] ||= 'Some files were unable to be copied'
            @response[:errorData][src.basename.to_s] = "already exists in '#{dst.dirname.relative_path_from(@root)}'"
          else
            if @params[:cut].to_i > 0
              src.rename(dst)
            else
              if src.directory?
                FileUtils.cp_r(src, dst)
              else
                FileUtils.copy(src, dst)
              end
            end
          end
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
        @targets.to_a.each do |target|
          remove_target(target)
        end
        @params[:tree] = true
        _open(@current)
      end
    end # of rm

    #
    def _duplicate
      if perms_for(@target)[:read] == false 
        @response[:error] = 'Access Denied'
        @response[:errorData][@target.basename.to_s] = 'Unable to read'
        return
      end
      if perms_for(@target.dirname)[:write] == false 
        @response[:error] = 'Access Denied'
        @response[:errorData][@target.dirname.to_s] = 'Unable to write'
        return
      end

      duplicate = @target.duplicate
      if @target.directory?
        FileUtils.cp_r(@target, duplicate)
      else
        FileUtils.copy(@target, duplicate)
      end
      @response[:select] = [to_hash(duplicate)]
      _open(@current)
    end # of duplicate

    # 
    def _read
      if perms_for(@target)[:read] == true
        @response[:content] = @target.read
      else
        @response[:error] = 'Access Denied'
      end
    end # of read

    #
    def _edit
      perms = perms_for(@target)
      if perms[:read] == true && perms[:write] == true
        @target.open('w') { |f| f.write @params[:content] }
        @response[:file] = cdc_for(@target)
      else
        @response[:error] = 'Access Denied'
      end
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
      if image_resize_handler.nil?
        command_not_implemented
      else
        if @target.file?
          perms = perms_for(@target)
          if perms[:read] == true && perms[:write] == true
            image_resize_handler.resize(@target, :width => @params[:width].to_i, :height => @params[:height].to_i)
            @response[:select] = [to_hash(@target)]
            _open(@current)
          else
            @response[:error] = 'Access Denied'
          end
        else
          @response[:error] = "Unable to resize file. It does not exist"
        end
      end
    end # of resize
    
    ################################################################################
    private

    #
    def remove_target(target)
      if target.directory?
        target.children.each do |child|
          remove_target(child)
        end
      end
      if perms_for(target)[:rm] == false
        @response[:error] ||= 'Some files/directories were unable to be removed'
        @response[:errorData][target.basename.to_s] = "Access Denied"
      else
        begin
          target.unlink
        rescue
          @response[:error] ||= 'Some files/directories were unable to be removed'
          @response[:errorData][target.basename.to_s] = "Remove failed"
        end
      end
    end

    #
    def mime_handler
      @options[:mime_handler]
    end

    #
    def image_size_handler
      @options[:image_size_handler]
    end

    #
    def image_resize_handler
      @options[:image_resize_handler]
    end

    # 
    def cwd_for(pathname)
      {
        :name => pathname.basename.to_s,
        :hash => to_hash(pathname),
        :mime => 'directory',
        :rel => (@options[:home] + '/' + pathname.relative_path_from(@root).to_s),
        :size => 0,
        :date => pathname.mtime.to_s,
      }.merge(perms_for(pathname))
    end

    # TODO - Implement link, linkTo, and parent
    def cdc_for(pathname)
      response = {
        :name => pathname.basename.to_s,
        :hash => to_hash(pathname),
        :date => pathname.mtime.to_s,
      }
      response.merge! perms_for(pathname)

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
        response.merge!(
          :size => pathname.size, 
          :mime => mime_handler.for(pathname),
          :url => (@options[:url] + '/' + pathname.relative_path_from(@root).to_s)
        )

        if pathname.readable? && response[:mime] =~ /image/ && !image_size_handler.nil? && !image_resize_handler.nil?
          response.merge!(
            :resize => true,
            :dim => image_size_handler.for(pathname)
          )
        end

      end

      return response
    end

    #
    def tree_for(root)
      root.children.select{ |child| child.directory? }.sort_by{|e| e.basename.to_s.downcase}.map { |child|
        {:name => child.basename.to_s,
         :hash => to_hash(child),
         :dirs => tree_for(child),
        }.merge(perms_for(child))
      }
    end # of tree_for

    #
    def perms_for(pathname, options = {})
      skip = [options[:skip]].flatten
      response = {}

      response[:read] = pathname.readable? if pathname.exist?
      response[:read] &&= specific_perm_for(pathname, :read)
      response[:read] &&= @options[:default_perms][:read] 

      response[:write] = pathname.writable? if pathname.exist?
      response[:write] &&= specific_perm_for(pathname, :write) 
      response[:write] &&= @options[:default_perms][:write]

      response[:rm] = pathname != @root 
      response[:rm] &&= specific_perm_for(pathname, :rm)
      response[:rm] &&= @options[:default_perms][:rm]

      response
    end # of perms_for

    #
    def specific_perm_for(pathname, perm)
      @options[:perms].select{ |k,v| pathname.relative_path_from(@root).to_s.send((k.is_a?(String) ? :== : :match), k) }.none?{|e| e.last[perm] == false}
    end # of specific_perm_for
    
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
