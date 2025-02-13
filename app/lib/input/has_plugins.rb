# frozen_string_literal: true

module Input
  module HasPlugins
    extend ActiveSupport::Concern

    included do
      @plugins = Plugins.new
    end

    module ClassMethods
      def inherited(base)
        super
        base.instance_variable_set(:@plugins, Plugins.new(plugins.to_a.dup))
      end

      def plugins
        @plugins
      end
    end
  end

  class Plugins
    def initialize(array = [])
      @plugins = array.to_a
    end

    def add(name, &block)
      @plugins << { name: name, defn: block }
    end

    def plug_to(object)
      @plugins.each { |p| object.send(:define_method, p[:name], p[:defn]) }
      object
    end

    def any?
      @plugins.any?
    end

    def to_a
      @plugins.to_a
    end
  end
end
