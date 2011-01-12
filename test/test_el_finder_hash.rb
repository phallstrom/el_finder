require 'el_finder_test_case'

class TestElFinder < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_to_hash_method
    assert_equal Base64.encode64('foo/bar').chomp, @elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'foo/bar'))
    assert_equal Base64.encode64('.').chomp, @elfinder.to_hash(ElFinder::Pathname.new(@vroot))
  end

  def test_from_hash_method
    assert_equal File.join(@vroot, 'foo/bar'), @elfinder.from_hash(Base64.encode64('foo/bar').chomp).to_s
    assert_equal @vroot, @elfinder.from_hash(Base64.encode64('.').chomp).to_s
  end

end
