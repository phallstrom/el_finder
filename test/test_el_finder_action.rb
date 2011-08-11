require 'el_finder_test_case'
require 'json'

class TestElFinderAction < Test::Unit::TestCase
  include ElFinderTestCase

  def test_create_basic_action
    test_class = Class.new do
      include ElFinder::Action

      el_finder do
        { :root => '/tmp/elfinder', :url => "/elfinder" }
      end

      attr_accessor :params, :headers, :render_opts

      def initialize
        @headers = {}
      end

      def render(*opts)
        @render_opts = opts
      end
    end.new

    assert test_class.respond_to?(:elfinder)

    test_class.params = { :cmd => 'open' }
    test_class.elfinder
  end
end

