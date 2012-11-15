# encoding: utf-8
require 'el_finder_test_case'

class TestElFinder < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_to_hash_method
    assert_equal Base64.urlsafe_encode64('foo/bar').chomp.tr("=\n", ""), @elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'foo/bar'))
    assert_equal Base64.urlsafe_encode64('.').chomp.tr("=\n", ""), @elfinder.to_hash(ElFinder::Pathname.new(@vroot))
  end

  def test_from_hash_method
    assert_equal File.join(@vroot, 'foo/bar'), @elfinder.from_hash(Base64.urlsafe_encode64('foo/bar').chomp).to_s
    assert_equal @vroot, @elfinder.from_hash(Base64.urlsafe_encode64('.').chomp).to_s
  end

  def test_from_hash_method_with_utf8
    assert_equal File.join(@vroot, 'Multimédia'), @elfinder.from_hash('TXVsdGltw6lkaWE').to_s
  end

end
