require "test/unit"
require "el_finder"
require "fileutils"

class TestElFinderPathname < Test::Unit::TestCase

  def setup
    @vroot = File.join(File.dirname(__FILE__), 'tmp')
    ::FileUtils.mkdir(@vroot)
  end

  def teardown
    ::FileUtils.rm_rf(@vroot)
  end

  def test_duplication_without_extension
    assert_equal 'README copy 1', ElFinder::Pathname.new(File.join(@vroot, 'README')).duplicate.basename.to_s
  end

  def test_2nd_duplication_without_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1'))
    assert_equal 'README copy 2', ElFinder::Pathname.new(File.join(@vroot, 'README')).duplicate.basename.to_s
  end

  def test_duplication_with_extension
    assert_equal 'README copy 1.txt', ElFinder::Pathname.new(File.join(@vroot, 'README.txt')).duplicate.basename.to_s
  end

  def test_2nd_duplication_with_extension
    ::FileUtils.touch(File.join(@vroot, 'README copy 1.txt'))
    assert_equal 'README copy 2.txt', ElFinder::Pathname.new(File.join(@vroot, 'README.txt')).duplicate.basename.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal 'README copy A copy 1.txt', ElFinder::Pathname.new(File.join(@vroot, 'README copy A.txt')).duplicate.basename.to_s
  end

  def test_duplication_of_duplication_lookalike
    assert_equal 'README copy copy 1.txt', ElFinder::Pathname.new(File.join(@vroot, 'README copy.txt')).duplicate.basename.to_s
  end

end
