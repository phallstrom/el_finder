module ElFinder
  module Action
    class << self
      def included(klass)
        klass.send(:extend, ElFinder::ActionClass)
      end
    end
  end

  module ActionClass
    def el_finder(name = :elfinder, &block)
      self.send(:define_method, name) do
        h, r = ElFinder::Connector.new(instance_eval(&block)).run(params)
        headers.merge!(h)
        render (r.empty? ? {:nothing => true} : {:text => r.to_json}), :layout => false
      end
    end
  end
end
