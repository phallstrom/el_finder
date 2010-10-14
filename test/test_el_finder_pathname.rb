require "test/unit"
require "el_finder"
require "fileutils"

class TestElFinderPathname < Test::Unit::TestCase

  def setup
    @vroot = "/tmp/elfinder"
    ElFinder::Pathname.root = @vroot
    ::FileUtils.mkdir(@vroot)
  end

  def teardown
    ::FileUtils.rm_rf(@vroot)
  end

  def test_root_path
    assert_equal @vroot, ElFinder::Pathname.root.to_s
  end

  def test_total_failure_if_root_is_nil
    ElFinder::Pathname.root = nil
    assert_nil ElFinder::Pathname.root
  end

  def test_cleanpath
    assert_equal File.join(@vroot, 'foo/bar'), ElFinder::Pathname.new(File.join('foo', '..', 'foo', 'bar')).to_s
  end

  def test_duplication_without_extension
    assert_equal File.join(@vroot, 'README copy 1'), ElFinder::Pathname.new('README').duplicate.to_s
  end

  def test_2nd_duplication_without_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1'))
    assert_equal File.join(@vroot, 'README copy 2'), ElFinder::Pathname.new('README').duplicate.to_s
  end

  def test_duplication_with_extension
    assert_equal File.join(@vroot, 'README copy 1.txt'), ElFinder::Pathname.new('README.txt').duplicate.to_s
  end

  def test_2nd_duplication_with_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1.txt'))
    assert_equal File.join(@vroot, 'README copy 2.txt'), ElFinder::Pathname.new('README.txt').duplicate.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal File.join(@vroot, 'README copy A copy 1.txt'), ElFinder::Pathname.new('README copy A.txt').duplicate.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal File.join(@vroot, 'README copy copy 1.txt'), ElFinder::Pathname.new('README copy.txt').duplicate.to_s
  end

end
