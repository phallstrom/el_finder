#
# http://elrte.org/redmine/projects/elfinder/wiki/Client-Server_Protocol_EN
#

require 'base64'

module ElFinder
  class Connector
    
    VALID_COMMANDS = %w[archive duplicate edit extract mkdir mkfile open paste ping read rename resize rm tmb upload]

    DEFAULT_OPTIONS = {
      :mime_handler => ElFinder::MimeType,
      :image_handler => ElFinder::Image,
      :original_filename_method => lambda {|file| file.original_filename},
      :disabled_commands => [],
      :allow_dot_files => true,
      :upload_max_size => '50M',
      :upload_file_mode => 0644,
      :archivers => {},
      :extractors => {},
      :home => 'Home',
      :default_perms => {:read => true, :write => true, :rm => true},
      :perms => [],
      :thumbs => false,
      :thumbs_directory => '.thumbs',
      :thumbs_size => 48,
      :thumbs_at_once => 5,
    }

    #
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)

      raise(RuntimeError, "Missing required :url option") unless @options.key?(:url) 
      raise(RuntimeError, "Missing required :root option") unless @options.key?(:root) 
      raise(RuntimeError, "Mime Handler is invalid") unless mime_handler.respond_to?(:for)
      raise(RuntimeError, "Image Handler is invalid") unless image_handler.nil? || ([:size, :resize, :thumbnail].all?{|m| image_handler.respond_to?(m)})

      @root = ElFinder::Pathname.new(options[:root])

      @headers = {}
      @response = {}
    end # of initialize

    #
    def run(params = {})
      @params = params.dup
      @headers = {}
      @response = {}
      @response[:errorData] = {}

      if VALID_COMMANDS.include?(@params[:cmd])

        if @options[:thumbs]
          @thumb_directory = @root + @options[:thumbs_directory]
          @thumb_directory.mkdir unless @thumb_directory.exist? 
          raise(RuntimeError, "Unable to create thumbs directory") unless @thumb_directory.directory?
        end

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
      Base64.encode64(pathname.path.to_s).chomp.tr("\n", "_")
    end # of to_hash

    #
    def from_hash(hash)
      pathname = @root + Base64.decode64(hash.tr("_", "\n"))
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
        @response[:cdc] = target.children.sort_by{|e| e.basename.to_s.downcase}.map{|e| cdc_for(e)}.compact

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
            :dotFiles => @options[:allow_dot_files],
            :uplMaxSize => @options[:upload_max_size],
            :archives => @options[:archivers].keys,
            :extract => @options[:extractors].keys,
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
      if !file.exist? && file.touch
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
        FileUtils.mv(file.path, dst.fullpath)
        FileUtils.chmod @options[:upload_file_mode], dst
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
            @response[:errorData][src.basename.to_s] = "already exists in '#{dst.dirname}'"
          else
            if @params[:cut].to_i > 0
              src.rename(dst)
            else
              if src.directory?
                FileUtils.cp_r(src.fullpath, dst.fullpath)
              else
                FileUtils.cp(src.fullpath, dst.fullpath)
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
        FileUtils.cp_r(@target, duplicate.fullpath)
      else
        FileUtils.copy(@target, duplicate.fullpath)
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
      @response[:error] = 'Invalid Parameters' and return unless @target.file? && @current.directory?
      @response[:error] = 'Access Denied' and return unless perms_for(@target)[:read] == true && perms_for(@current)[:write] == true
      @response[:error] = 'No extractor available for this file type' and return if (extractor = @options[:extractors][mime_handler.for(@target)]).nil?
      cmd = ['cd', @current.to_s.shellescape, '&&', extractor.map(&:shellescape), @target.basename.to_s.shellescape].flatten.join(' ')
      if system(cmd)
        @params[:tree] = true
        _open(@current)
      else
        @response[:error] = 'Unable to extract files from archive'
      end
    end # of extract

    #
    def _archive
      @response[:error] = 'Invalid Parameters' and return unless !@targets.nil? && @targets.all?{|e| e.exist?} && @current.directory?
      @response[:error] = 'Access Denied' and return unless !@targets.nil? && @targets.all?{|e| perms_for(e)[:read]} && perms_for(@current)[:write] == true
      @response[:error] = 'No archiver available for this file type' and return if (archiver = @options[:archivers][@params[:type]]).nil?
      extension = archiver.shift
      basename = @params[:name] || @targets.first.basename_sans_extension
      archive = (@root + "#{basename}#{extension}").unique
      cmd = ['cd', @current.to_s.shellescape, '&&', archiver.map(&:shellescape), archive.to_s.shellescape, @targets.map{|t| t.basename.to_s.shellescape}].flatten.join(' ')
      if system(cmd)
        @response[:select] = [to_hash(archive)]
        _open(@current)
      else
        @response[:error] = 'Unable to create archive'
      end
    end # of archive

    #
    def _tmb
      if image_handler.nil?
        command_not_implemented
      else
        @response[:current] = to_hash(@current)
        @response[:images] = {}
        idx = 0
        @current.children.select{|e| mime_handler.for(e) =~ /image/}.each do |img|
          if idx >= @options[:thumbs_at_once]
            @response[:tmb] = true
            break
          end
          thumbnail = thumbnail_for(img)
          unless thumbnail.file?
            image_handler.thumbnail(img, thumbnail, :width => @options[:thumbs_size].to_i, :height => @options[:thumbs_size].to_i)
            @response[:images][to_hash(img)] = @options[:url] + '/' + thumbnail.path.to_s
            idx += 1
          end
        end
      end

    end # of tmb

    #
    def _resize
      if image_handler.nil?
        command_not_implemented
      else
        if @target.file?
          perms = perms_for(@target)
          if perms[:read] == true && perms[:write] == true
            image_handler.resize(@target, :width => @params[:width].to_i, :height => @params[:height].to_i)
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
    def thumbnail_for(pathname)
      @thumb_directory + "#{to_hash(pathname)}.png"
    end

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
          if @options[:thumbs] and (thumbnail = thumbnail_for(target)).file?
            thumbnail.unlink
          end
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
    def image_handler
      @options[:image_handler]
    end

    # 
    def cwd_for(pathname)
      {
        :name => pathname.basename.to_s,
        :hash => to_hash(pathname),
        :mime => 'directory',
        :rel => pathname.is_root? ? @options[:home] : (@options[:home] + '/' + pathname.path.to_s),
        :size => 0,
        :date => pathname.mtime.to_s,
      }.merge(perms_for(pathname))
    end

    def cdc_for(pathname)
      return nil if @options[:thumbs] && pathname.to_s == @thumb_directory.to_s
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
      elsif pathname.file?
        response.merge!(
          :size => pathname.size, 
          :mime => mime_handler.for(pathname),
          :url => (@options[:url] + '/' + pathname.path.to_s)
        )

        if pathname.readable? && response[:mime] =~ /image/ && !image_handler.nil?
          response.merge!(
            :resize => true,
            :dim => image_handler.size(pathname)
          )
          if @options[:thumbs] 
            if (thumbnail = thumbnail_for(pathname)).exist?
              response.merge!( :tmb => (@options[:url] + '/' + thumbnail.path.to_s))
            else
              @response[:tmb] = true 
            end
          end
        end

      end

      if pathname.symlink?
        response.merge!(
          :link => to_hash(@root + pathname.readlink), # hash of file to which point link
          :linkTo => (@root + pathname.readlink).relative_to(pathname.dirname.path).to_s, # relative path to
          :parent => to_hash((@root + pathname.readlink).dirname) # hash of directory in which is linked file 
        )
      end

      return response
    end

    #
    def tree_for(root)
      root.children.
      select{ |child| child.directory? }.
      reject{ |child| child.to_s == @thumb_directory.to_s }.
      sort_by{|e| e.basename.to_s.downcase}.
      map { |child|
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

      response[:rm] = !pathname.is_root?
      response[:rm] &&= specific_perm_for(pathname, :rm)
      response[:rm] &&= @options[:default_perms][:rm]

      response
    end # of perms_for

    #
    def specific_perm_for(pathname, perm)
      pathname = pathname.path if pathname.is_a?(ElFinder::Pathname)
      @options[:perms].select{ |k,v| pathname.to_s.send((k.is_a?(String) ? :== : :match), k) }.none?{|e| e.last[perm] == false}
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
