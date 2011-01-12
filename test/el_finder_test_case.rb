require 'test/unit'
require 'el_finder'
require 'pp'

module ElFinderTestCase 

  def setup
    @vroot = '/tmp/elfinder'
    FileUtils.mkdir_p(@vroot)
    FileUtils.cp_r "#{File.dirname(__FILE__)}/files/.",  @vroot
    @elfinder = ElFinder::Connector.new({
      :root => @vroot, 
      :url => '/elfinder', 
      :original_filename_method => lambda {|file| File.basename(file.path)}
    })
  end

  def teardown
    FileUtils.rm_rf(@vroot)
  end

end
