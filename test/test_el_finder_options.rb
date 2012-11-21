# encoding: utf-8
require 'el_finder_test_case'

class TestElFinder < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_to_hash_method
    @elfinder.options = {} # default is '50M'
    assert_equal (50 * 1024 * 1024), @elfinder.send(:upload_max_size_in_bytes)
  end

  def test_from_hash_method
    @elfinder.options = {
      :upload_max_size => 1
    }
    assert_equal 1, @elfinder.send(:upload_max_size_in_bytes)
  end

  def test_from_hash_method
    @elfinder.options = {
      :upload_max_size => '1'
    }
    assert_equal 1, @elfinder.send(:upload_max_size_in_bytes)
  end

  def test_from_hash_method
    @elfinder.options = {
      :upload_max_size => '1K'
    }
    assert_equal 1024, @elfinder.send(:upload_max_size_in_bytes)
  end

  def test_from_hash_method
    @elfinder.options = {
      :upload_max_size => '1G'
    }
    assert_equal 1073741824, @elfinder.send(:upload_max_size_in_bytes)
  end

end
