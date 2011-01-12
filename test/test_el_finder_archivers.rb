require 'el_finder_test_case'

class TestElFinderExtractors < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_archive_is_empty_by_default
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal [], r[:params][:archives]
  end

  def test_archive_is_correct_when_set
    @elfinder.options = {
      :archivers => {
        'application/zip' => ['.zip', 'zip', '-qr9'],
        'application/x-tar' => ['.tar', 'tar', '-cf'],
        'application/x-gzip' => ['.tgz', 'tar', '-czf'],
        'application/x-bzip2' => ['.tbz', 'tar', '-cjf'],
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal 4, r[:params][:archives].size
    assert r[:params][:archives].include? 'application/zip'
    assert r[:params][:archives].include? 'application/x-tar'
    assert r[:params][:archives].include? 'application/x-gzip'
    assert r[:params][:archives].include? 'application/x-bzip2'
  end

  def test_no_archiver_available
    @elfinder.options = { :archivers => { 'application/zip' => ['zip', '-qr9'] } }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    files = r[:cdc].select{|e| e[:name] =~ /\.png$/}
    h, r = @elfinder.run(:cmd => 'archive', :type => 'bogus/archiver', :targets => files.map{|f| f[:hash]}, :current => r[:cwd][:hash])
    assert_match(/no archiver available/i, r[:error])
  end

  def test_bogus_target
    @elfinder.options = { :archivers => { 'application/zip' => ['zip', '-qr9'] } }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'archive', :type => 'application/zip', :targets => ['INVALID'], :current => r[:cwd][:hash])
    assert_match(/invalid parameters/i, r[:error])
  end

  def test_bogus_current
    @elfinder.options = { :archivers => { 'application/zip' => ['.zip', 'zip', '-qr9'] } }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    files = r[:cdc].select{|e| e[:name] =~ /\.png$/}
    h, r = @elfinder.run(:cmd => 'archive', :type => 'application/zip', :targets => files.map{|f| f[:hash]}, :current => 'INVALID')
    assert_match(/invalid parameters/i, r[:error])
  end

  def test_permissions_no_read_on_target
    @elfinder.options = { 
      :perms => { 'pjkh.png' => {:read => false} },
      :archivers => { 'application/zip' => ['.zip', 'zip', '-qr9'] } 
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    files = r[:cdc].select{|e| e[:name] =~ /\.png$/}
    h, r = @elfinder.run(:cmd => 'archive', :type => 'application/zip', :targets => files.map{|f| f[:hash]}, :current => r[:cwd][:hash])
    assert_match(/access denied/i, r[:error])
  end

  def test_permissions_no_write_on_current
    @elfinder.options = { 
      :perms => { '.' => {:write => false} },
      :archivers => { 'application/zip' => ['.zip', 'zip', '-qr9'] } 
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    files = r[:cdc].select{|e| e[:name] =~ /\.png$/}
    h, r = @elfinder.run(:cmd => 'archive', :type => 'application/zip', :targets => files.map{|f| f[:hash]}, :current => r[:cwd][:hash])
    assert_match(/access denied/i, r[:error])
  end

  def test_successful_archive
    raise "Unable to find 'zip' in your PATH. This test requires zip to run." if `which zip`.chomp.empty?
    @elfinder.options = { :archivers => { 'application/zip' => ['.zip', 'zip', '-qr9'] } }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    files = r[:cdc].select{|e| e[:name] =~ /\.png$/}
    h, r = @elfinder.run(:cmd => 'archive', :name => 'Archive', :type => 'application/zip', :targets => files.map{|f| f[:hash]}, :current => r[:cwd][:hash])

    assert File.exist?(File.join(@vroot, 'Archive.zip'))
    assert_not_nil r[:select]
    assert_nil r[:error]
  end

  def test_successful_archive_with_default_name
    raise "Unable to find 'zip' in your PATH. This test requires zip to run." if `which zip`.chomp.empty?
    @elfinder.options = { :archivers => { 'application/zip' => ['.zip', 'zip', '-qr9'] } }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    files = r[:cdc].select{|e| e[:name] =~ /\.png$/}
    h, r = @elfinder.run(:cmd => 'archive', :type => 'application/zip', :targets => files.map{|f| f[:hash]}, :current => r[:cwd][:hash])

    assert File.exist?(File.join(@vroot, "#{files.first[:name].chomp('.png')}.zip"))
    assert_not_nil r[:select]
    assert_nil r[:error]
  end


  ################################################################################


end
