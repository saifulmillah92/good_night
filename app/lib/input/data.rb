# frozen_string_literal: true

module Input
  module Data
    extend ActiveSupport::Concern
    include HasAliases
    include HasKeys

    delegate :with_indifferent_access,
             :each_pair,
             :empty?,
             :each,
             to: :output,
             allow_nil: true

    def initialize(attributes)
      super()
      @nested_attributes = Attributes::Nested.new
      assign_attributes(attributes)
      set_defaults
    end

    def assign_attributes(attributes)
      @nested_attributes.clear_all
      @attributes = apply_aliases(Attributes.new(attributes))
    end

    def [](name)
      @attributes[name.to_sym]
    end

    def []=(name, value)
      @nested_attributes.clear(name.to_sym)
      apply_aliases(name.to_sym => value).each do |n, v|
        @attributes[n] = v
      end
    end

    def set_defaults
      keys.each_default(self) do |name, value|
        @attributes[name] = value unless key?(name)
      end
    end

    def key?(name)
      @attributes.key?(name.to_sym)
    end

    def attributes
      @attributes.dup
    end

    def output
      result = attributes

      keys
        .to_a
        .select { |k| key?(k.to_sym) }
        .select { |k| respond_to?("#{k}_output") }
        .each { |k| result[k.to_sym] = public_send("#{k}_output") }

      result.transform_keys { |k| self.class.key_transformer[k] }.to_h
    end

    module ClassMethods
      def inherited(base)
        super
        base.instance_variable_set(:@key_transformer, key_transformer)
      end

      def output_keys(**mapping)
        @key_transformer = key_transformer.merge(mapping)
      end

      def key_transformer
        @key_transformer ||= Hash.new { |_h, k| k }
      end

      def define_child(key, klass)
        key.set_metadata(:nested, true)
        name = key.to_s
        builder = "build_#{name}"

        include(
          Module.new do
            define_method(builder) { |*args| klass.new(*args) }
            define_method("#{name}_output") { public_send(name).output }
            define_method(name) do
              @nested_attributes.get(name) do
                public_send(builder, self[name]) if key?(name)
              end
            end
          end,
        )
      end

      def define_children(key, klass)
        key.set_metadata(:nested, true)
        name = key.to_sym
        builder = "build_#{name.to_s.singularize}"

        include(
          Module.new do
            define_method(builder) { |*args| klass.new(*args) }
            define_method("#{name}_output") do
              public_send(name).map(&:output)
            end
            define_method(name) do
              @nested_attributes.get(name) do
                value = self[name]
                if value.is_a?(Array)
                  value.map { |v| public_send(builder, v) }
                else
                  []
                end
              end
            end
          end,
        )
      end
    end
  end
end
