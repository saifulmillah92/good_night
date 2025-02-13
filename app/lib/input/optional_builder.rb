# frozen_string_literal: true

module Input
  class OptionalBuilder
    def initialize(subject, key, options = {})
      @subject = subject
      @key = key
      @options = options
    end

    def default(x = nil, &block)
      raise "Cannot accept both default value and default block" if x && block

      check_default(default: x || block)
    end

    def string(**opts)
      @key.set_metadata(:type, :string)

      validates_with(Validators::StringValidator, opts)
    end

    def number(**opts)
      @key.set_metadata(:type, :number)

      validates_with(Validators::NumberValidator, opts)
    end

    def any_of(enum, **opts)
      @key.set_metadata(:type, :enum)
      @key.set_metadata(:values, enum)

      inclusion = ActiveModel::Validations::InclusionValidator
      validates_with(inclusion, **opts, in: enum)
    end

    def array(class_name = @key.to_s.singularize.camelize, **opts, &defn)
      item_type = opts[:of] || opts[:with]
      @key.set_metadata(:type, :array)
      @key.set_metadata(:item_type, item_type)

      klass = opts[:as]
      opts = opts.except(:as)

      if klass && defn
        raise "cannot accept both :as and a block"
      elsif !klass && !defn
        validates_with(Validators::ArrayValidator, opts)
      else
        validates_with(Validators::HashArrayValidator, opts)
        klass ||= class_for_nested_attributes(class_name, &defn)
        @subject.define_children(@key, klass)
      end
    end

    def hash(class_name = @key.to_s.singularize.camelize, **opts, &defn)
      @key.set_metadata(:type, :object)

      klass = opts[:as]
      opts = opts.except(:as)

      raise "cannot accept both :as and a block" if klass && defn

      validates_with(Validators::HashNestedValidator, opts)
      klass ||= class_for_nested_attributes(class_name, &defn)
      @subject.define_child(@key, klass)
    end

    private

    def validates_with(validator, opts)
      options = build_options(opts.merge(attributes: [@key.to_sym]))
      @subject.validates_with(validator, options)
    end

    def validates_each(opts, &block)
      @subject.validates_each(@key.to_sym, build_options(opts), &block)
    end

    def build_options(options)
      options = check_default(options)
      @options.merge(options)
    end

    def check_default(opts)
      @key.set_default(opts[:default]) unless opts[:default].nil?
      opts.except(:default)
    end

    def class_for_nested_attributes(class_name, &defn)
      klass = Class.new(@subject.base_class)
      klass.instance_variable_set(:@plugins, @subject.plugins)
      klass.send(:class_eval, &defn)
      @subject.const_set(class_name, klass)
      klass
    end
  end
end
