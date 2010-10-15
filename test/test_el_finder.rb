require "test/unit"
require "el_finder"

class TestElFinder < Test::Unit::TestCase

  def test_true
    true
  end

  def setup
    @vroot = '/tmp/elfinder'
    FileUtils.mkdir_p(@vroot)
    FileUtils.cp_r "#{File.dirname(__FILE__)}/files/.",  @vroot
    @elfinder = ElFinder::Connector.new({:root => @vroot, :url => '/elfinder'})
  end

  def teardown
    FileUtils.rm_rf(@vroot)
  end

  def test_should_fail_initialization_if_required_options_not_passed
    assert_raise RuntimeError do
      ElFinder::Connector.new()
    end
  end

  def test_should_fail_initialization_if_no_root_specified
    assert_raise RuntimeError do
      ElFinder::Connector.new({:url => '/elfinder'})
    end
  end

  def test_should_fail_initialization_if_no_url_specified
    assert_raise RuntimeError do
      ElFinder::Connector.new({:root => '/tmp/elfinder'})
    end
  end

  def test_should_fail_initialization_if_mime_handler_is_invalid
    assert_raise RuntimeError do
      ElFinder::Connector.new({:root => '/tmp/elfinder', :url => '/elfinder', :mime_handler => Object})
    end
  end

  def test_should_return_two_hashes
    h, r = @elfinder.run({})
    assert_instance_of Hash, h
    assert_instance_of Hash, r
  end


  def test_should_return_invalid_request_if_command_is_invalid
    h, r = @elfinder.run({:cmd => 'INVALID'})
    assert_not_nil r[:error]
    assert_match /invalid command/i, r[:error]
  end

  def test_should_return_debug_information_when_configured_to
    elfinder = ElFinder::Connector.new({:root => '/tmp/elfinder', :url => '/elfinder', :debug => false})
    h, r = elfinder.run({:cmd => 'INVALID'})
    assert_nil r[:debug]

    elfinder = ElFinder::Connector.new({:root => '/tmp/elfinder', :url => '/elfinder', :debug => true})
    h, r = elfinder.run({:cmd => 'INVALID'})
    assert_not_nil r[:debug]
  end

  def test_to_hash_method
    assert_equal 'foo/bar', @elfinder.to_hash(ElFinder::Pathname.new_with_root(@vroot, 'foo/bar'))
    assert_equal '/', @elfinder.to_hash(ElFinder::Pathname.new_with_root(@vroot))
  end

  def test_from_hash_method
    assert_equal File.join(@vroot, 'foo/bar'), @elfinder.from_hash('foo/bar').to_s
    assert_equal @vroot, @elfinder.from_hash('').to_s
  end


end
