require "test/unit"
require "el_finder"

class TestMimeType < Test::Unit::TestCase

  def test_that_method_exists
    assert_respond_to ElFinder::MimeType, :for
  end

  def test_known_mime_types
    assert_equal 'image/jpeg', ElFinder::MimeType.for('image.jpg')
  end

  def test_unknown_mime_types
    assert_equal 'unknown/unknown', ElFinder::MimeType.for('image.foo')
  end

  def test_uppercase_extensions
    assert_equal 'image/jpeg', ElFinder::MimeType.for('image.JPG')
  end

  def test_missing_extension
    assert_equal 'unknown/unknown', ElFinder::MimeType.for('README')
  end

  def test_passing_pathname
    assert_equal 'text/plain', ElFinder::MimeType.for(ElFinder::Pathname.new('/tmp', 'README.txt'))
  end

end
