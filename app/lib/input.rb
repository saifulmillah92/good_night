# frozen_string_literal: true

module Input
  extend ActiveSupport::Concern
  include Validatable
  include HasPlugins

  included do
    @optional_builder = OptionalBuilder
    @required_builder = RequiredBuilder
  end

  module ClassMethods
    def inherited(base)
      super
      base.instance_variable_set(:@optional_builder, @optional_builder)
      base.instance_variable_set(:@required_builder, @optional_builder)
    end

    IS_KEY = ->(name) { ->(o) { o.key?(name) } }

    def optional(name)
      @optional_builder.new(self, key(name), if: IS_KEY[name])
    end

    def required(name)
      validate do
        (key?(name) && attributes[name].present?) || errors.add(name, :blank)
      end
      @required_builder.new(self, key(name), if: IS_KEY[name])
    end

    def base_class
      Input::Base
    end

    def plugin(name, &block)
      base = self
      define_singleton_method(:base_class) { base }
      @plugins.add(name, &block)
      @optional_builder = plugins.plug_to(Class.new(OptionalBuilder))
      @required_builder = plugins.plug_to(Class.new(RequiredBuilder))
    end
  end

  class Base
    include Input
  end
end
