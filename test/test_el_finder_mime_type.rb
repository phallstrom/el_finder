require "test/unit"
require "el_finder"

class TestElFinderMimeType < Test::Unit::TestCase

  def test_that_method_exists
    assert_respond_to ElFinder::MimeType, :for_pathname
  end

  def test_known_mime_types
    assert_equal 'image/jpeg', ElFinder::MimeType.for_pathname('image.jpg')
  end

  def test_unknown_mime_types
    assert_equal 'application/octet-stream', ElFinder::MimeType.for_pathname('image.foo')
  end

  def test_uppercase_extensions
    assert_equal 'image/jpeg', ElFinder::MimeType.for_pathname('image.JPG')
  end

  def test_missing_extension
    assert_equal 'application/octet-stream', ElFinder::MimeType.for_pathname('README')
  end

end
