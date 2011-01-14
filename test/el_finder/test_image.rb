require "test/unit"
require "el_finder"

class TestImage < Test::Unit::TestCase

  def test_that_method_exists
    assert_respond_to ElFinder::Image, :size
  end

  def test_that_logos_are_correct_size
    assert_equal '70x66', ElFinder::Image.size( File.join(File.dirname(__FILE__), '../files/elfinder.png') )
    assert_equal '100x100', ElFinder::Image.size( File.join(File.dirname(__FILE__), '../files/pjkh.png') )
  end

  def test_that_nil_is_returned_on_non_images
    assert_equal nil, ElFinder::Image.size( File.join(File.dirname(__FILE__), '../files/README.txt') )
  end

  def test_that_nil_is_returned_on_nonexistint_files
    assert_equal nil, ElFinder::Image.size( File.join(File.dirname(__FILE__), '../files/NON_EXIST') )
  end

end
