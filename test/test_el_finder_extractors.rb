require 'el_finder_test_case'

class TestElFinderExtractors < Test::Unit::TestCase

  include ElFinderTestCase

  ################################################################################

  def test_extract_is_empty_by_default
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal [], r[:params][:extract]
  end

  def test_extract_is_correct_when_set
    @elfinder.options = {
      :extractors => {
        'application/zip' => ['unzip'],
        'application/x-tar' => ['tar', '-xf'],
        'application/x-gzip' => ['tar', '-xzf'],
        'application/x-bzip2' => ['tar', '-xjf'],
      }
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    assert_equal 4, r[:params][:extract].size
    assert r[:params][:extract].include? 'application/zip'
    assert r[:params][:extract].include? 'application/x-tar'
    assert r[:params][:extract].include? 'application/x-gzip'
    assert r[:params][:extract].include? 'application/x-bzip2'
  end

  def test_no_extractor_available
    @elfinder.options = { :extractors => { 'application/zip' => ['unzip'] } }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'pjkh.png'}
    h, r = @elfinder.run(:cmd => 'extract', :target => file[:hash], :current => r[:cwd][:hash])
    assert_match(/no extractor available/i, r[:error])
  end

  def test_bogus_target
    @elfinder.options = { 
      :extractors => { 'application/zip' => ['unzip'] } 
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    h, r = @elfinder.run(:cmd => 'extract', :target => 'INVALID', :current => r[:cwd][:hash])
    assert_match(/invalid parameters/i, r[:error])
  end

  def test_bogus_current
    @elfinder.options = { 
      :extractors => { 'application/zip' => ['unzip'] } 
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'sample.zip'}
    h, r = @elfinder.run(:cmd => 'extract', :target => file[:hash], :current => 'INVALID')
    assert_match(/invalid parameters/i, r[:error])
  end

  def test_permissions_no_read_on_target
    @elfinder.options = { 
      :perms => { 'sample.zip' => {:read => false} },
      :extractors => { 'application/zip' => ['unzip'] } 
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'sample.zip'}
    h, r = @elfinder.run(:cmd => 'extract', :target => file[:hash], :current => r[:cwd][:hash])
    assert_match(/access denied/i, r[:error])
  end

  def test_permissions_no_write_on_current
    @elfinder.options = { 
      :perms => { '.' => {:write => false} },
      :extractors => { 'application/zip' => ['unzip'] } 
    }
    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'sample.zip'}
    h, r = @elfinder.run(:cmd => 'extract', :target => file[:hash], :current => r[:cwd][:hash])
    assert_match(/access denied/i, r[:error])
  end

  def test_successful_extraction
    raise "Unable to find 'unzip' in your PATH. This test requires unzip to run." if `which unzip`.chomp.empty?
    @elfinder.options = { :extractors => { 'application/zip' => ['unzip', '-qq', '-o'] } }

    h, r = @elfinder.run(:cmd => 'open', :init => 'true', :target => '')
    file = r[:cdc].find{|e| e[:name] == 'sample.zip'}
    h, r = @elfinder.run(:cmd => 'extract', :target => file[:hash], :current => r[:cwd][:hash])

    assert File.directory?(File.join(@vroot, 'unzipped'))
    assert File.exist?(File.join(@vroot, 'unzipped/one'))
    assert File.exist?(File.join(@vroot, 'unzipped/two'))
    assert File.directory?(File.join(@vroot, 'unzipped/subdir'))
    assert File.exist?(File.join(@vroot, 'unzipped/subdir/three'))
    assert_not_nil r[:tree]
    assert_nil r[:error]
  end



  ################################################################################


end
