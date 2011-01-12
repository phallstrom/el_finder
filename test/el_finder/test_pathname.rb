require 'test/unit'
require 'el_finder'
require 'fileutils'
require 'pp'

class TestPathname < Test::Unit::TestCase

  def setup
    @vroot = '/tmp/elfinder'
    FileUtils.mkdir_p(@vroot)
    FileUtils.cp_r "#{File.dirname(__FILE__)}/../files/.",  @vroot
  end

  def teardown
    FileUtils.rm_rf(@vroot)
  end

  ################################################################################

  def test_new_fails_without_root
    assert_raise ArgumentError do
      ElFinder::Pathname.new()
    end
  end

  def test_new_okay_with_root
    assert_nothing_raised do
      ElFinder::Pathname.new(@vroot)
    end
  end

  def test_new_okay_with_root_and_path
    assert_nothing_raised do
      ElFinder::Pathname.new(@vroot, 'foo.txt')
    end
  end

  def test_instance_variables_are_set_correctly
    p = ElFinder::Pathname.new(@vroot, 'foo.txt')
    assert_equal @vroot, p.root.to_s
    assert_equal 'foo.txt', p.path.to_s
  end

  def test_instance_variables_are_set_correctly_with_nil_path
    p = ElFinder::Pathname.new(@vroot)
    assert_equal @vroot, p.root.to_s
    assert_equal '.', p.path.to_s
  end

  def test_instance_variables_are_kind_of_pathname
    p = ElFinder::Pathname.new(@vroot, 'foo.txt')
    assert_kind_of ::Pathname, p.root
    assert_kind_of ::Pathname, p.path
  end

  def test_attempt_to_break_out_of_root_using_relative_path
    assert_raise SecurityError do
      p = ElFinder::Pathname.new(@vroot, '../foo.txt')
    end
  end

  def test_attempt_to_break_out_of_root_using_absolute_path
    assert_raise SecurityError do
      p = ElFinder::Pathname.new(@vroot, '/foo.txt')
    end
  end

  def test_new_with_full_path_matching_root
    p = ElFinder::Pathname.new(@vroot, "#{@vroot}/foo.txt")
    assert_equal 'foo.txt', p.path.to_s
  end

  def test_new_with_full_path_matching_root_realpath
    p = ElFinder::Pathname.new(@vroot, "#{Pathname.new(@vroot).realpath.to_s}/foo.txt")
    assert_equal 'foo.txt', p.path.to_s
  end

  def test_plus_string
    p = ElFinder::Pathname.new(@vroot, 'foo')
    p1 = p + 'bar'
    assert_equal 'foo/bar', p1.path.to_s
  end

  def test_plus_pathname
    p = ElFinder::Pathname.new(@vroot, 'foo')
    p1 = p + Pathname.new('bar')
    assert_equal 'foo/bar', p1.path.to_s
  end

  def test_plus_elfinder_pathname
    p = ElFinder::Pathname.new(@vroot, 'foo')
    p1 = p + ElFinder::Pathname.new(@vroot, 'bar')
    assert_equal 'foo/bar', p1.path.to_s
  end

  def test_fullpath
    assert_equal "#{@vroot}/one/two/three.txt", ElFinder::Pathname.new(@vroot, 'one/two/three.txt').fullpath.to_s
  end

  def test_file?
    assert_equal true, ElFinder::Pathname.new(@vroot, 'README.txt').file?, "README.txt should be a file"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'INVALID').file?, "INVALID should not be a file"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'foo').file?, "foo should not be a file (it's a directory)"
  end

  def test_directory?
    assert_equal true, ElFinder::Pathname.new(@vroot, 'foo').directory?, "foo should be a directory"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'README.txt').directory?, "README.txt should not be a directory (it's a file)"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'INVALID').directory?, "INVALID should not be a directory"
  end

  def test_exist?
    assert_equal true, ElFinder::Pathname.new(@vroot, 'foo').exist?, "foo should exist"
    assert_equal true, ElFinder::Pathname.new(@vroot, 'README.txt').exist?, "README.txt should exist"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'INVALID').exist?, "INVALID should not exist"
  end

  def test_symlink?
    File.symlink(File.join(@vroot, 'README.txt'), File.join(@vroot, 'symlink.txt'))
    assert_equal true, ElFinder::Pathname.new(@vroot, 'symlink.txt').symlink?, "symlink.txt should be a symlink"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'README.txt').symlink?, "README.txt should not be a symlink"
  end

  def test_readable?
    assert_equal true, ElFinder::Pathname.new(@vroot, 'foo').readable?, "foo should be readable"
    assert_equal true, ElFinder::Pathname.new(@vroot, 'README.txt').readable?, "README.txt should be readable"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'INVALID').readable?, "INVALID should not be readable"
  end

  def test_writable?
    assert_equal true, ElFinder::Pathname.new(@vroot, 'foo').writable?, "foo should be writable"
    assert_equal true, ElFinder::Pathname.new(@vroot, 'README.txt').writable?, "README.txt should be writable"
    assert_equal false, ElFinder::Pathname.new(@vroot, 'INVALID').writable?, "INVALID should not be writable"
  end

  def test_mtime
    assert_equal File.new(File.join(@vroot, 'foo')).mtime, ElFinder::Pathname.new(@vroot, 'foo').mtime
    assert_equal File.new(File.join(@vroot, 'README.txt')).mtime, ElFinder::Pathname.new(@vroot, 'README.txt').mtime
    assert_raise Errno::ENOENT do
      ElFinder::Pathname.new(@vroot, 'INVALID').mtime
    end
  end

  def test_unlink
    assert_equal true, ElFinder::Pathname.new(@vroot, 'README.txt').exist?
    ElFinder::Pathname.new(@vroot, 'README.txt').unlink
    assert_equal false, ElFinder::Pathname.new(@vroot, 'README.txt').exist?
    assert_raise Errno::ENOENT do
      ElFinder::Pathname.new(@vroot, 'INVALID').unlink
    end
    assert_raise Errno::ENOTEMPTY do
      ElFinder::Pathname.new(@vroot, 'foo').unlink
    end
  end

  def test_basename
    assert_equal 'README.txt', ElFinder::Pathname.new(@vroot, 'README.txt').basename.to_s
    assert_equal 'README', ElFinder::Pathname.new(@vroot, 'README.txt').basename('.txt').to_s
    assert_equal 'tom.txt', ElFinder::Pathname.new(@vroot, 'foo/tom.txt').basename.to_s
  end

  def test_basename_sans_extension
    assert_equal 'README', ElFinder::Pathname.new(@vroot, 'README.txt').basename_sans_extension.to_s
    assert_equal 'tom', ElFinder::Pathname.new(@vroot, 'foo/tom.txt').basename_sans_extension.to_s
  end

  def test_dirname
    assert_equal '.', ElFinder::Pathname.new(@vroot, 'README.txt').dirname.path.to_s
    assert_equal 'foo', ElFinder::Pathname.new(@vroot, 'foo/tom.txt').dirname.path.to_s
  end

  def test_to_s
    assert_equal "#{@vroot}/README.txt", ElFinder::Pathname.new(@vroot, 'README.txt').to_s
    assert_equal "#{@vroot}/foo/tom.txt", ElFinder::Pathname.new(@vroot, 'foo/tom.txt').to_s
  end

  def test_children
    children = ElFinder::Pathname.new(@vroot, 'foo').children
    assert_equal 4, children.size
    assert_equal %w[philip sam sandy tom], children.map{|e| e.basename_sans_extension.to_s}.sort
  end

  def test_mkdir
    p = ElFinder::Pathname.new(@vroot, 'some-dir')
    assert_equal false, p.directory?
    p.mkdir
    assert_equal true, p.directory?
  end

  def test_read
    p = ElFinder::Pathname.new(@vroot, 'foo/philip.txt')
    assert_equal File.read(File.join(@vroot, 'foo/philip.txt')), p.read
  end

  def test_touch
    p = ElFinder::Pathname.new(@vroot, 'newfile')
    p.touch
    assert_equal true, p.file?
  end

  def test_open
    p = ElFinder::Pathname.new(@vroot, 'newfile')
    assert_equal false, p.file?
    p.open('w') {|f| f.puts "new"}
    assert_equal true, p.file?
    assert_equal File.read(File.join(@vroot, 'newfile')), p.read
  end

  def test_unique_on_create
    file = ElFinder::Pathname.new(@vroot, 'foo.txt')
    assert_equal 'foo.txt', file.unique.basename.to_s
  end

  def test_unique_conflict
    file = ElFinder::Pathname.new(@vroot, 'pjkh.png')
    assert_equal 'pjkh 1.png', file.unique.basename.to_s
  end

  def test_unique_conflict_twice
    ElFinder::Pathname.new(@vroot, 'pjkh 1.png').touch
    file = ElFinder::Pathname.new(@vroot, 'pjkh.png')
    assert_equal 'pjkh 2.png', file.unique.basename.to_s
  end


  def test_duplication_without_extension
    assert_equal File.join(@vroot, 'README copy 1'), ElFinder::Pathname.new(@vroot,'README').duplicate.fullpath.to_s
  end

  def test_2nd_duplication_without_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1'))
    assert_equal File.join(@vroot, 'README copy 2'), ElFinder::Pathname.new(@vroot,'README').duplicate.fullpath.to_s
  end

  def test_duplication_with_extension
    assert_equal File.join(@vroot, 'README copy 1.txt'), ElFinder::Pathname.new(@vroot,'README.txt').duplicate.fullpath.to_s
  end

  def test_2nd_duplication_with_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1.txt'))
    assert_equal File.join(@vroot, 'README copy 2.txt'), ElFinder::Pathname.new(@vroot,'README.txt').duplicate.fullpath.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal File.join(@vroot, 'README copy A copy 1.txt'), ElFinder::Pathname.new(@vroot,'README copy A.txt').duplicate.fullpath.to_s
  end

  def test_duplication_of_duplication_lookalike2
    assert_equal File.join(@vroot, 'README copy copy 1.txt'), ElFinder::Pathname.new(@vroot,'README copy.txt').duplicate.fullpath.to_s
  end

  def test_on_disk_duplication
    file = ElFinder::Pathname.new(@vroot, 'README.txt')
    file.touch
    assert_equal true, File.exist?(File.join(@vroot, 'README.txt'))
    duplicate = file.duplicate
    duplicate.touch
    assert_equal true, File.exist?(File.join(@vroot, 'README copy 1.txt'))
  end

  def test_rename_on_same_filesystem
    file = ElFinder::Pathname.new(@vroot, 'old.txt')
    file.touch
    assert_equal true, File.exist?(File.join(@vroot, 'old.txt'))
    file.rename(File.join(@vroot, 'new.txt'))
    assert_equal false, File.exist?(File.join(@vroot, 'old.txt'))
    assert_equal true, File.exist?(File.join(@vroot, 'new.txt'))
    assert_equal 'new.txt', file.path.to_s
  end

  def test_rename_on_different_filesystem
    if File.directory?('/Volumes/MyBook')
      file = ElFinder::Pathname.new(@vroot, 'old.txt')
      file.touch
      assert_equal true, File.exist?(File.join(@vroot, 'old.txt'))

      File.symlink('/Volumes/MyBook', File.join(@vroot, 'mybook'))
      assert_equal true, File.symlink?(File.join(@vroot, 'mybook'))
      assert_equal '/Volumes/MyBook', File.readlink(File.join(@vroot, 'mybook'))

      file.rename('mybook/elfinder.rename.test.safe.to.delete')
      assert_equal false, File.exist?(File.join(@vroot, 'old.txt'))
      assert_equal true, File.exist?('/Volumes/MyBook/elfinder.rename.test.safe.to.delete')
      file.unlink
      assert_equal false, File.exist?('/Volumes/MyBook/elfinder.rename.test.safe.to.delete')
    end
  end

end
