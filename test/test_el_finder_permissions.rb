require 'el_finder_test_case'

class TestElFinder < Test::Unit::TestCase

  include ElFinderTestCase

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

  def test_custom_permissions_on_root
    @elfinder.options = {
      :perms => {
        '.' => {:read => false},
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_match(/access denied/i, r[:error])
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
        assert_equal true, e[:write]
        assert_equal false, e[:rm]
      when 'foo'
        assert_equal true, e[:read]
        assert_equal true, e[:write]
        assert_equal false, e[:rm]
      when 'pjkh.png'
        assert_equal false, e[:read]
        assert_equal true, e[:write]
        assert_equal false, e[:rm]
      when 'README.txt'
        assert_equal true, e[:read]
        assert_equal false, e[:write]
        assert_equal true, e[:rm]
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

  def test_custom_permissions_in_subdirectories
    @elfinder.options = {
      :perms => {
        %r{foo/s.*} => {:read => false}
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'open', :target => r[:cdc].find{|e| e[:name] == 'foo'}[:hash])

    r[:cdc].each do |e|
      case e[:name]
      when 'sandy.txt', 'sam.txt'
        assert_equal false, e[:read]
      else 
        assert_equal true, e[:read]
      end
    end
  end

  def test_open_permissions
    @elfinder.options = {
      :perms => {
        'foo' => {:read => false}
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'foo'}
    h1, r = @elfinder.run(:cmd => 'open', :target => target[:hash])
    assert_match(/access denied/i, r[:error])
  end

  def test_mkdir_permissions
    @elfinder.options = {
      :perms => {
        'foo' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'foo'}
    h1, r = @elfinder.run(:cmd => 'open', :target => target[:hash])

    h, r = @elfinder.run(:cmd => 'mkdir', :current => r[:cwd][:hash], :name => 'dir1')
    assert !File.directory?(File.join(@vroot, 'foo', 'dir1'))
    assert_nil r[:select]
    assert_match(/access denied/i, r[:error])
  end

  def test_mkfile_permissions
    @elfinder.options = {
      :perms => {
        'foo' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'foo'}
    h1, r = @elfinder.run(:cmd => 'open', :target => target[:hash])

    h, r = @elfinder.run(:cmd => 'mkfile', :current => r[:cwd][:hash], :name => 'file1')
    assert !File.file?(File.join(@vroot, 'foo', 'file1'))
    assert_nil r[:select]
    assert_match(/access denied/i, r[:error])
  end

  def test_rename_permissions_file_rm_false
    @elfinder.options = {
      :perms => {
        'README.txt' => {:rm => false}
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h1, r = @elfinder.run(:cmd => 'rename', :target => target[:hash], :current => r[:cwd][:hash], :name => 'file1')
    assert File.file?(File.join(@vroot, 'README.txt'))
    assert !File.file?(File.join(@vroot, 'file1'))
    assert_nil r[:select]
    assert_match(/access denied/i, r[:error])
  end

  def test_rename_permissions_dir_write_false
    @elfinder.options = {
      :perms => {
        '.' => {:write => false}
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h1, r = @elfinder.run(:cmd => 'rename', :target => target[:hash], :current => r[:cwd][:hash], :name => 'file1')
    assert File.file?(File.join(@vroot, 'README.txt'))
    assert !File.file?(File.join(@vroot, 'file1'))
    assert_nil r[:select]
    assert_match(/access denied/i, r[:error])
  end

  def test_upload_permissions
    @elfinder.options = {
      :perms => {
        '.' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    uploads = []
    uploads << File.open(File.join(@vroot, 'foo/philip.txt'))
    h, r = @elfinder.run(:cmd => 'upload', :upload => uploads, :current => r[:cwd][:hash])
    assert !File.exist?(File.join(@vroot, 'philip.txt'))
    assert_nil r[:select]
    assert_match(/access denied/i, r[:error])
  end

  def test_paste_permissions_on_dst
    @elfinder.options = {
      :perms => {
        'foo' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    targets = r[:cdc].select{|e| e[:mime] != 'directory'}
    dst = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'paste', :targets => targets.map{|e| e[:hash]}, :dst => dst[:hash])
    assert_match(/access denied/i, r[:error])
    assert !File.exist?(File.join(@vroot, 'foo', 'README.txt'))
    assert !File.exist?(File.join(@vroot, 'foo', 'pjkh.png'))
    assert !File.exist?(File.join(@vroot, 'foo', 'elfinder.png'))
  end

  def test_paste_permissions_on_target
    @elfinder.options = {
      :perms => {
        'README.txt' => {:read => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    targets = r[:cdc].select{|e| e[:mime] != 'directory'}
    dst = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'paste', :targets => targets.map{|e| e[:hash]}, :dst => dst[:hash])
    assert !File.exist?(File.join(@vroot, 'foo', 'README.txt'))
    assert File.exist?(File.join(@vroot, 'foo', 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'foo', 'elfinder.png'))
  end

  def test_rm_permissions_file_rm_false
    @elfinder.options = {
      :perms => {
        /.*\.png/ => {:rm => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'rm', :targets => r[:cdc].map{|e| e[:hash]})

    assert !File.exist?(File.join(@vroot, 'README.txt'))
    assert File.exist?(File.join(@vroot, 'pjkh.png'))
    assert File.exist?(File.join(@vroot, 'elfinder.png'))
    assert !File.exist?(File.join(@vroot, 'foo'))

    assert_match(/unable to be removed/i, r[:error])
    assert_match(/access denied/i, r[:errorData].to_s)
  end

  def test_rm_permissions_chmod_perm_hack
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    File.unlink(File.join(@vroot, 'pjkh.png'))
    h, r = @elfinder.run(:cmd => 'rm', :targets => r[:cdc].map{|e| e[:hash]})

    assert_match(/unable to be removed/i, r[:error])
    assert_match(/pjkh.png.*remove failed/i, r[:errorData].to_s)
  end

  def test_duplicate_permissions_file
    @elfinder.options = {
      :perms => {
        'README.txt' => {:read => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    duplicate = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'duplicate', :target => duplicate[:hash])
    assert !File.exist?(File.join(@vroot, 'README copy 1.txt'))
    assert_match(/access denied/i, r[:error])
    assert_match(/unable to read/i, r[:errorData].to_s)
  end

  def test_duplicate_permissions_directory
    @elfinder.options = {
      :perms => {
        '.' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    duplicate = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'duplicate', :target => duplicate[:hash])
    assert !File.exist?(File.join(@vroot, 'README copy 1.txt'))
    assert_match(/access denied/i, r[:error])
    assert_match(/unable to write/i, r[:errorData].to_s)
  end


  def test_read_file_permissions
    @elfinder.options = {
      :perms => {
        'README.txt' => {:read => false}
      }
    }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'read', :target => target[:hash])
    
    assert_nil r[:content]
    assert_match(/access denied/i, r[:error])
  end

  def test_edit_permissions_write
    @elfinder.options = {
      :perms => {
        'README.txt' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'edit', :target => file[:hash], :content => 'Hello')
    assert_match(/access denied/i, r[:error])
    assert_not_equal 'Hello', File.read(File.join(@vroot, 'README.txt'))
  end

  def test_edit_permissions_read
    @elfinder.options = {
      :perms => {
        'README.txt' => {:read => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'README.txt'}
    h, r = @elfinder.run(:cmd => 'edit', :target => file[:hash], :content => 'Hello')
    assert_match(/access denied/i, r[:error])
    assert_not_equal 'Hello', File.read(File.join(@vroot, 'README.txt'))
  end

  def test_resize_permissions_write
    @elfinder.options = {
      :perms => {
        'pjkh.png' => {:write => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'pjkh.png'}
    h, r = @elfinder.run(:cmd => 'resize', :target => file[:hash], :current => r[:cwd][:hash], :width => '50', :height => '25')
    assert_match(/access denied/i, r[:error])
    assert File.exist?(File.join(@vroot, 'pjkh.png'))
    assert_equal '100x100', ElFinder::ImageSize.for(File.join(@vroot, 'pjkh.png')).to_s
  end

  def test_resize_permissions_read
    @elfinder.options = {
      :perms => {
        'pjkh.png' => {:read => false}
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'pjkh.png'}
    h, r = @elfinder.run(:cmd => 'resize', :target => file[:hash], :current => r[:cwd][:hash], :width => '50', :height => '25')
    assert_match(/access denied/i, r[:error])
    assert File.exist?(File.join(@vroot, 'pjkh.png'))
    assert_equal '100x100', ElFinder::ImageSize.for(File.join(@vroot, 'pjkh.png')).to_s
  end


end
