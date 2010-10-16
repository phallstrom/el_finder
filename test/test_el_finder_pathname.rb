require "test/unit"
require "el_finder"
require "fileutils"

class TestElFinderPathname < Test::Unit::TestCase

  def setup
    @vroot = '/tmp/elfinder'
    FileUtils.mkdir_p(@vroot)
    FileUtils.cp_r "#{File.dirname(__FILE__)}/files/.",  @vroot
  end

  def teardown
    FileUtils.rm_rf(@vroot)
  end

  ################################################################################

  def test_paths_are_always_clean
    assert_equal File.join(@vroot, 'foo/bar'), ElFinder::Pathname.new_with_root(@vroot, File.join('foo', '..', 'foo', 'bar')).to_s
    assert_equal @vroot, ElFinder::Pathname.new_with_root(@vroot, '').to_s
    assert_equal File.join(@vroot, 'foo/bar'), ElFinder::Pathname.new_with_root(@vroot, File.join('/foo', 'bar')).to_s
  end

  def test_duplication_without_extension
    assert_equal File.join(@vroot, 'README copy 1'), ElFinder::Pathname.new_with_root(@vroot,'README').duplicate.to_s
  end

  def test_2nd_duplication_without_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1'))
    assert_equal File.join(@vroot, 'README copy 2'), ElFinder::Pathname.new_with_root(@vroot,'README').duplicate.to_s
  end

  def test_duplication_with_extension
    assert_equal File.join(@vroot, 'README copy 1.txt'), ElFinder::Pathname.new_with_root(@vroot,'README.txt').duplicate.to_s
  end

  def test_2nd_duplication_with_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1.txt'))
    assert_equal File.join(@vroot, 'README copy 2.txt'), ElFinder::Pathname.new_with_root(@vroot,'README.txt').duplicate.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal File.join(@vroot, 'README copy A copy 1.txt'), ElFinder::Pathname.new_with_root(@vroot,'README copy A.txt').duplicate.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal File.join(@vroot, 'README copy copy 1.txt'), ElFinder::Pathname.new_with_root(@vroot,'README copy.txt').duplicate.to_s
  end

  def test_on_disk_duplication
    file = ElFinder::Pathname.new_with_root(@vroot, 'README.txt')
    FileUtils.touch(file)
    assert_equal true, File.exist?(File.join(@vroot, 'README.txt'))
    duplicate = file.duplicate
    FileUtils.touch(duplicate)
    assert_equal true, File.exist?(File.join(@vroot, 'README copy 1.txt'))
  end

  ################################################################################

  def test_relative_to_method
    assert_equal "", ElFinder::Pathname.new_with_root(@vroot).relative_to(::Pathname.new(@vroot)).to_s
    assert_equal "foo.txt", ElFinder::Pathname.new_with_root(@vroot, 'foo.txt').relative_to(::Pathname.new(@vroot)).to_s
    assert_equal "foo/bar.txt", ElFinder::Pathname.new_with_root(@vroot, 'foo/bar.txt').relative_to(::Pathname.new(@vroot)).to_s
  end

  ################################################################################

  def test_class_type
    assert_kind_of ElFinder::Pathname, ElFinder::Pathname.new_with_root(@vroot, 'foo')
    assert_kind_of ElFinder::Pathname, ElFinder::Pathname.new_with_root(@vroot, 'foo') + 'bar'
    assert_kind_of ElFinder::Pathname, ElFinder::Pathname.new_with_root(@vroot, 'foo').join('bar')
  end

end
