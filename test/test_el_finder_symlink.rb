require 'el_finder_test_case'

class TestElFinderSymlink < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_ruby_symlink_creation
    File.symlink(File.join(@vroot, 'pjkh.png'), File.join(@vroot, 'symlink.png'))
    assert File.symlink?(File.join(@vroot, 'symlink.png'))
    assert_equal File.join(@vroot, 'pjkh.png'), File.readlink(File.join(@vroot, 'symlink.png'))

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
  end

  def test_same_directory
    File.symlink(File.join(@vroot, 'pjkh.png'), File.join(@vroot, 'symlink.png'))
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    source = r[:cdc].find{|e| e[:name] == 'pjkh.png'}
    target = r[:cdc].find{|e| e[:name] == 'symlink.png'}
    assert_equal 'image/png', target[:mime]
    assert_equal source[:hash], target[:link]
    assert_equal 'pjkh.png', target[:linkTo]
    assert_equal r[:cwd][:hash], target[:parent]
  end

  def test_sub_directory
    File.symlink(File.join(@vroot, 'pjkh.png'), File.join(@vroot, 'foo', 'symlink.png'))

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    home = r[:cwd]
    source = r[:cdc].find{|e| e[:name] == 'pjkh.png'}
    foo = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'open', :target => foo[:hash])
    target = r[:cdc].find{|e| e[:name] == 'symlink.png'}

    assert_equal source[:hash], target[:link]
    assert_equal '../pjkh.png', target[:linkTo]
    assert_equal home[:hash], target[:parent]
  end

  def test_parent_directory
    File.symlink(File.join(@vroot, 'foo', 'tom.txt'), File.join(@vroot, 'symlink.txt'))

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    target = r[:cdc].find{|e| e[:name] == 'symlink.txt'}
    foo = r[:cdc].find{|e| e[:name] == 'foo'}

    h, r = @elfinder.run(:cmd => 'open', :target => foo[:hash])
    source = r[:cdc].find{|e| e[:name] == 'tom.txt'}

    pp source
    pp target

    assert_equal source[:hash], target[:link]
    assert_equal 'foo/tom.txt', target[:linkTo]
    assert_equal foo[:hash], target[:parent]
  end

  def test_sibling_directory
    FileUtils.mkdir(File.join(@vroot, 'bar'))
    File.symlink(File.join(@vroot, 'foo', 'tom.txt'), File.join(@vroot, 'bar', 'symlink.txt'))

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    foo = r[:cdc].find{|e| e[:name] == 'foo'}
    bar = r[:cdc].find{|e| e[:name] == 'bar'}

    h, r = @elfinder.run(:cmd => 'open', :target => foo[:hash])
    source = r[:cdc].find{|e| e[:name] == 'tom.txt'}

    h, r = @elfinder.run(:cmd => 'open', :target => bar[:hash])
    target = r[:cdc].find{|e| e[:name] == 'symlink.txt'}

    assert_equal source[:hash], target[:link]
    assert_equal '../foo/tom.txt', target[:linkTo]
    assert_equal foo[:hash], target[:parent]
  end

end
