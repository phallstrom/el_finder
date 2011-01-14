require 'el_finder_test_case'

class TestElFinderThumbs < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_tmb_is_false_by_default
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal nil, r[:tmb]
  end

  def test_thumbs_directory_does_not_show_in_output
    @elfinder.options = { :thumbs => true, :thumbs_directory => '.thumbs' }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == '.thumbs'}
    assert_equal true, target.nil?
  end

  def test_thumbs_directory_exists
    @elfinder.options = { :thumbs => true, :thumbs_directory => '.thumbs' }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal true, File.directory?(File.join(@vroot, '.thumbs'))
  end

  def test_thumbs_directory_cannot_be_created
    FileUtils.touch(File.join(@vroot, '.thumbs'))
    @elfinder.options = { :thumbs => true, :thumbs_directory => '.thumbs' }
    assert_raise RuntimeError do
      h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    end
  end

  # 
  # In the root there are a two images: elfinder.png, pjkh.png
  #

  def test_tmb_is_true_when_thumbs_enabled_and_images_exist_without_thumbnail
    @elfinder.options = { :thumbs => true }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal true, r[:tmb]
  end

  def test_tmb_is_false_when_thumbs_enabled_and_images_exist_with_thumbnail
    @elfinder.options = { :thumbs => true }
    Dir.mkdir(File.join(@vroot, '.thumbs'))
    FileUtils.touch(File.join(@vroot, '.thumbs', "#{@elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'elfinder.png'))}.png"))
    FileUtils.touch(File.join(@vroot, '.thumbs', "#{@elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'pjkh.png'))}.png"))
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal nil, r[:tmb]
  end

  def test_thumbs_are_created_when_requested
    @elfinder.options = { :thumbs => true }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'tmb', :current => '')
    assert_equal true, File.exist?(File.join(@vroot, '.thumbs', "#{@elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'elfinder.png'))}.png"))
    assert_equal true, File.exist?(File.join(@vroot, '.thumbs', "#{@elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'pjkh.png'))}.png"))
  end

  def test_thumbs_of_non_images_are_not_created
    @elfinder.options = { :thumbs => true }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'tmb', :current => '')
    assert_equal false, File.exist?(File.join(@vroot, '.thumbs', "#{@elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'README.txt'))}.png"))
  end

  def test_tmb_response
    @elfinder.options = { :thumbs => true }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'tmb', :current => '')

    elfinder_hash = @elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'elfinder.png'))
    pjkh_hash = @elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'elfinder.png'))

    assert_equal 2, r[:images].size
    assert_equal "/elfinder/.thumbs/#{elfinder_hash}.png", r[:images][elfinder_hash]
    assert_equal "/elfinder/.thumbs/#{pjkh_hash}.png", r[:images][pjkh_hash]
  end

  def test_tmb_more_to_be_created
    @elfinder.options = { :thumbs => true, :thumbs_at_once => 1 }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'tmb', :current => '')

    elfinder_hash = @elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'elfinder.png'))
    pjkh_hash = @elfinder.to_hash(ElFinder::Pathname.new(@vroot, 'elfinder.png'))

    assert_equal true, r[:tmb]
    assert_equal 1, r[:images].size
  end



  ################################################################################


end
