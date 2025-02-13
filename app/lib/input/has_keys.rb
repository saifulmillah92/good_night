# frozen_string_literal: true

module Input
  module HasKeys
    extend ActiveSupport::Concern

    def keys
      self.class.keys
    end

    included do
      @keys = Keys.new
    end

    module ClassMethods
      def inherited(base)
        super
        base.instance_variable_set("@keys", Keys.new(@keys))
      end

      def keys
        @keys
      end

      def key(name, **metadata)
        Key.new(name, **metadata).tap { |key| @keys << key }
      end
    end
  end

  class Keys
    def initialize(input = nil)
      @set = Array(input)
    end

    def <<(key)
      @set = @set.reject { |k| k.is?(key) } << key
    end

    def [](name)
      @set.find { |key| key.is?(name) }
    end

    def each_default(object, &block)
      @set.each { |key| key.on_default(object, &block) }
      self
    end

    def each(&block)
      @set.each(&block)
    end

    def to_a
      @set.to_a.dup
    end
  end

  class Key
    delegate :to_s, :to_sym, to: :@attr_name

    def initialize(attr_name, metadata = {})
      @attr_name = attr_name.to_sym
      @metadata = metadata
    end

    def is?(attr_name)
      to_s == attr_name.to_s
    end

    def set_metadata(key, value)
      @metadata[key] = value
    end

    def metadata
      @metadata.deep_dup
    end

    def set_default(default)
      @default = default
    end

    def on_default(obj)
      return unless defined?(@default)
      yield(@attr_name, default_value(obj))
    end

    def default_value(obj)
      if @default.respond_to?(:call)
        @default.arity == 0 ? @default.call : @default.call(obj)
      else
        @default
      end
    end
  end
end
