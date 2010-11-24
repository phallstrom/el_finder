require 'test/unit'
require 'el_finder'
require 'pp'

class TestElFinder < Test::Unit::TestCase

  def setup
    @vroot = '/tmp/elfinder'
    FileUtils.mkdir_p(@vroot)
    FileUtils.cp_r "#{File.dirname(__FILE__)}/files/.",  @vroot
    @elfinder = ElFinder::Connector.new({
      :root => @vroot, 
      :url => '/elfinder', 
      :original_filename_method => lambda {|file| File.basename(file.path)}
    })
  end

  def teardown
    FileUtils.rm_rf(@vroot)
  end

  ################################################################################

  def test_should_fail_initialization_if_required_options_not_passed
    assert_raise RuntimeError do
      ElFinder::Connector.new()
    end
  end

  def test_should_fail_initialization_if_no_root_specified
    assert_raise RuntimeError do
      ElFinder::Connector.new({:url => '/elfinder'})
    end
  end

  def test_should_fail_initialization_if_no_url_specified
    assert_raise RuntimeError do
      ElFinder::Connector.new({:root => '/tmp/elfinder'})
    end
  end

  def test_should_fail_initialization_if_mime_handler_is_invalid
    assert_raise RuntimeError do
      ElFinder::Connector.new({:root => '/tmp/elfinder', :url => '/elfinder', :mime_handler => Object})
    end
  end

  ################################################################################

  def test_should_return_two_hashes
    h, r = @elfinder.run({})
    assert_instance_of Hash, h
    assert_instance_of Hash, r
  end


  def test_should_return_invalid_request_if_command_is_invalid
    h, r = @elfinder.run({:cmd => 'INVALID'})
    assert_not_nil r[:error]
    assert_match(/invalid command/i, r[:error])
  end
  
  ################################################################################

  def test_to_hash_method
    assert_equal Base64.encode64('foo/bar').chomp, @elfinder.to_hash(ElFinder::Pathname.new_with_root(@vroot, 'foo/bar'))
    assert_equal Base64.encode64('/').chomp, @elfinder.to_hash(ElFinder::Pathname.new_with_root(@vroot))
  end

  def test_from_hash_method
    assert_equal File.join(@vroot, 'foo/bar'), @elfinder.from_hash(Base64.encode64('foo/bar').chomp).to_s
    assert_equal @vroot, @elfinder.from_hash(Base64.encode64('').chomp).to_s
  end

  ################################################################################

  def test_init_via_open
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_not_nil r[:cwd]
    assert_not_nil r[:cdc]
    assert_not_nil r[:disabled]
    assert_not_nil r[:params]
    r[:cdc].each do |e|
      case e[:name]
        when 'foo'
          assert_nil e[:dim]
          assert_nil e[:resize]
          assert_equal 'directory', e[:mime]
          assert_equal 0, e[:size]
        when 'pjkh.png'
          assert_equal '100x100', e[:dim]
          assert e[:resize]
          assert_equal 'image/png', e[:mime]
          assert_equal 1142, e[:size]
      end
    end
  end

  def test_mkdir
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h1, r1 = @elfinder.run(:cmd => 'mkdir', :current => r[:cwd][:hash], :name => 'dir1')
    assert File.directory?(File.join(@vroot, 'dir1'))
    assert_not_nil r1[:select]

    h1, r1 = @elfinder.run(:cmd => 'mkdir', :current => r[:cwd][:hash], :name => 'dir1')
    assert_match(/unable/i, r1[:error])

    h1, r1 = @elfinder.run(:cmd => 'mkdir', :current => r[:cwd][:hash], :name => 'foo')
    assert_match(/unable/i, r1[:error])
  end

  def test_mkfile
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h1, r1 = @elfinder.run(:cmd => 'mkfile', :current => r[:cwd][:hash], :name => 'file1')
    assert File.file?(File.join(@vroot, 'file1'))
    assert_not_nil r1[:select]

    h1, r1 = @elfinder.run(:cmd => 'mkfile', :current => r[:cwd][:hash], :name => 'file1')
    assert_match(/unable/i, r1[:error])

    h1, r1 = @elfinder.run(:cmd => 'mkfile', :current => r[:cwd][:hash], :name => 'README.txt')
    assert_match(/unable/i, r1[:error])
  end

  def test_rename_ok
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h1, r1 = @elfinder.run(:cmd => 'rename', :target => target[:hash], :current => r[:cwd][:hash], :name => 'file1')
    assert File.file?(File.join(@vroot, 'file1'))
    assert_not_nil r1[:select]
  end

  def test_rename_fail
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h1, r1 = @elfinder.run(:cmd => 'rename', :target => target[:hash], :current => r[:cwd][:hash], :name => 'foo')
    assert_match(/unable.*already exists/i, r1[:error])
    assert File.file?(File.join(@vroot, 'README.txt'))
    assert_nil r1[:select]
  end

  def test_upload
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    uploads = []
    uploads << File.open(File.join(@vroot, 'foo/philip.txt'))
    uploads << File.open(File.join(@vroot, 'foo/sandy.txt'))
    h, r = @elfinder.run(:cmd => 'upload', :upload => uploads, :current => r[:cwd][:hash])
    assert File.exist?(File.join(@vroot, 'philip.txt'))
    assert File.exist?(File.join(@vroot, 'sandy.txt'))
    assert_not_nil r[:select]
  end

  def test_ping
    h, r = @elfinder.run(:cmd => 'ping')
    assert r.empty?
    assert_equal 'Close', h['Connection']
  end

  def test_paste_copy
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    targets = r[:cdc].select{|e| e[:mime] != 'directory'}
    dst = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'paste', :targets => targets.map{|e| e[:hash]}, :dst => dst[:hash])
    assert_not_nil r[:tree]
    assert File.exist?(File.join(@vroot, 'README.txt'))
    assert File.exist?(File.join(@vroot, 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'elfinder.png'))
    assert File.exist?(File.join(@vroot, 'foo', 'README.txt'))
    assert File.exist?(File.join(@vroot, 'foo', 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'foo', 'elfinder.png'))
  end

  def test_paste_cut
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    targets = r[:cdc].select{|e| e[:mime] != 'directory'}
    dst = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'paste', :targets => targets.map{|e| e[:hash]}, :dst => dst[:hash], :cut => '1')
    assert_not_nil r[:tree]
    assert !File.exist?(File.join(@vroot, 'README.txt'))
    assert !File.exist?(File.join(@vroot, 'pjkh.png'))
    assert !File.exist?(File.join(@vroot, 'elfinder.png'))
    assert File.exist?(File.join(@vroot, 'foo', 'README.txt'))
    assert File.exist?(File.join(@vroot, 'foo', 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'foo', 'elfinder.png'))
  end

  def test_paste_partial_failure
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'mkfile', :current => r[:cwd][:hash], :name => 'philip.txt')
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')

    targets = r[:cdc].select{|e| e[:mime] != 'directory'}
    dst = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'paste', :targets => targets.map{|e| e[:hash]}, :dst => dst[:hash])
    assert_not_nil r[:tree]
    assert_match(/unable to be copied/i, r[:error])
    assert_not_nil r[:errorData]
    assert_equal 1, r[:errorData].size
    assert File.exist?(File.join(@vroot, 'philip.txt'))
    assert File.exist?(File.join(@vroot, 'foo', 'philip.txt'))
    assert File.exist?(File.join(@vroot, 'foo', 'README.txt'))
    assert File.exist?(File.join(@vroot, 'foo', 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'foo', 'elfinder.png'))
  end

  def test_rm
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'rm', :current => r[:cwd][:hash], :targets => [])
    assert_match(/no files/i, r[:error])

    h, r = @elfinder.run(:cmd => 'rm', :targets => r[:cdc].reject{|e| e[:mime] =~ /image/}.map{|e| e[:hash]})
    assert !File.exist?(File.join(@vroot, 'README.txt'))
    assert File.exist?(File.join(@vroot, 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'elfinder.png'))
    assert !File.exist?(File.join(@vroot, 'foo'))
  end

  def test_duplicate
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    duplicate = r[:cdc].find{|e| e[:name] == 'README.txt'}
    assert File.exist?(File.join(@vroot, 'README.txt'))
    h, r = @elfinder.run(:cmd => 'duplicate', :target => duplicate[:hash])
    assert File.exist?(File.join(@vroot, 'README copy 1.txt'))
    assert_not_nil r[:select]
    h, r = @elfinder.run(:cmd => 'duplicate', :target => duplicate[:hash])
    assert File.exist?(File.join(@vroot, 'README copy 2.txt'))
  end

  def test_read
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'read', :target => file[:hash])
    assert_equal r[:content], File.read(File.join(@vroot, 'README.txt'))
  end

  def test_edit
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'edit', :target => file[:hash], :content => 'Hello')
    assert_equal 'Hello', File.read(File.join(@vroot, 'README.txt'))
    assert_not_nil r[:file]
  end

  def test_resize
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'pjkh.png'}
    h, r = @elfinder.run(:cmd => 'resize', :target => file[:hash], :current => r[:cwd][:hash], :width => '50', :height => '25')
    assert File.exist?(File.join(@vroot, 'pjkh.png'))
    assert_equal '50x25', ElFinder::ImageSize.for(File.join(@vroot, 'pjkh.png')).to_s
  end

  ################################################################################

  def test_default_permissions
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')

    assert_equal true, r[:cwd][:read]
    assert_equal true, r[:cwd][:write]
    assert_equal false, r[:cwd][:rm]

    r[:cdc].each do |e|
      assert_equal true, e[:read]
      assert_equal true, e[:write]
      assert_equal true, e[:rm]
    end
  end

  def test_default_permissions
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')

    assert_equal true, r[:cwd][:read]
    assert_equal true, r[:cwd][:write]
    assert_equal false, r[:cwd][:rm]

    r[:cdc].each do |e|
      assert_equal true, e[:read]
      assert_equal true, e[:write]
      assert_equal true, e[:rm]
    end
  end

  def test_custom_permissions
    @elfinder.options = {
      :perms => {
        'foo' => {:rm => false},
        /.*.png$/ => {:rm => false},
        /^pjkh/ => {:read => false},
        'README.txt' => {:write => false},
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')

    r[:cdc].each do |e|
      case e[:name]
      when 'elfinder.png'
        assert_equal true, e[:read]
        assert_equal false, e[:write]
        assert_equal false, e[:rm]
      when 'foo'
        assert_equal true, e[:read]
        assert_equal true, e[:write]
        assert_equal false, e[:rm]
      when 'pjkh.png'
        assert_equal false, e[:read]
        assert_equal false, e[:write]
        assert_equal false, e[:rm]
      when 'README.txt'
        assert_equal true, e[:read]
        assert_equal false, e[:write]
        assert_equal false, e[:rm]
      end
    end
  end

  def test_custom_permissions_multiple_matches_prefers_false
    @elfinder.options = {
      :perms => {
        'pjkh.png' => {:read => false},
        /pjkh/ => {:read => true},
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')

    r[:cdc].each do |e|
      case e[:name]
      when 'pjkh.png'
        assert_equal false, e[:read]
        assert_equal true, e[:write]
        assert_equal true, e[:rm]
      else 
        assert_equal true, e[:read]
        assert_equal true, e[:write]
        assert_equal true, e[:rm]
      end
    end
  end

=begin
  def test_rm_permissions
    @elfinder.options = {:perms => ['^foo/s.*' => {:rm => false}]}

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'open', :target => r[:cdc].find{|e| e[:name] == 'foo'}[:hash])

    h, r = @elfinder.run(:cmd => 'rm', :targets => r[:cdc].map{|e| e[:hash]})
    assert !File.exist?(File.join(@vroot, 'philip.txt'))
    assert File.exist?(File.join(@vroot, 'sam.txt'))
    assert File.exist?(File.join(@vroot, 'sandy.txt'))
    assert !File.exist?(File.join(@vroot, 'tom.txt'))
  end
=end

end

__END__
/Users/philip/Desktop/el_finder/test/files
14615625       16 -rw-r--r--    1 philip   staff        7718 Oct 15 14:19 ./elfinder.png
14569851        0 drwxr-xr-x    6 philip   staff         204 Oct 15 11:19 ./foo
14605469        8 -rw-r--r--    1 philip   staff           7 Oct 15 11:19 ./foo/philip.txt
14605474        8 -rw-r--r--    1 philip   staff           4 Oct 15 11:19 ./foo/sam.txt
14605479        8 -rw-r--r--    1 philip   staff           6 Oct 15 11:19 ./foo/sandy.txt
14605486        8 -rw-r--r--    1 philip   staff           4 Oct 15 11:19 ./foo/tom.txt
14569820        8 -rw-r--r--    1 philip   staff        1142 Dec  6  2007 ./pjkh.png
14605515        8 -rw-r--r--    1 philip   staff         186 Oct 15 11:20 ./README.txt
